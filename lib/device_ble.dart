// Transport Bluetooth LE ke firmware S3 Air (tahap firmware BLE) — untuk
// mode lapangan saat WiFi rumah tidak terjangkau. Protokol teks di atas
// GATT: perintah ditulis ke karakteristik CMD (diakhiri '\n'), jawaban
// mengalir lewat notifikasi RESP dan ditutup notifikasi penanda tepat
// satu byte 0x0A. Meter + RTA tiba sebagai paket biner 55 byte lewat
// notifikasi METER tiap 50 ms (meterPush tidak null).
// Satu permintaan berjalan pada satu waktu (dikunci bergiliran).
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device_transport.dart';
import 'models.dart';

class BleTransport implements DeviceTransport {
  final BluetoothDevice device;
  BleTransport._(this.device);

  static final Guid serviceUuid =
      Guid('9e7319c0-3a6d-4f7a-b001-5a33a1c00001');
  static final Guid cmdUuid = Guid('9e7319c0-3a6d-4f7a-b001-5a33a1c00002');
  static final Guid respUuid = Guid('9e7319c0-3a6d-4f7a-b001-5a33a1c00003');
  static final Guid meterUuid = Guid('9e7319c0-3a6d-4f7a-b001-5a33a1c00004');

  BluetoothCharacteristic? _cmd, _resp, _meter;
  StreamSubscription<List<int>>? _respSub, _meterSub;
  final StreamController<MeterData> _meterCtl =
      StreamController<MeterData>.broadcast();
  MeterData _lastMeter = const MeterData();
  List<double> _lastRta = const [];
  bool _closed = false;

  // --- kunci bergiliran: satu permintaan CMD pada satu waktu -----------------
  Future<void> _tail = Future.value();

  Future<T> _serialized<T>(Future<T> Function() fn) {
    final result = _tail.then((_) => fn());
    // Ekor rantai tidak boleh membawa galat: permintaan berikutnya tetap
    // jalan walau yang sebelumnya gagal.
    _tail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  // --- penampung jawaban RESP -------------------------------------------------
  final List<int> _respBuf = [];
  Completer<String>? _respCompleter;

  void _onResp(List<int> data) {
    // Notifikasi tepat [0x0A] = akhir jawaban; byte muatan tidak pernah
    // mengandung 0x0A, jadi penanda ini tidak ambigu.
    if (data.length == 1 && data[0] == 0x0A) {
      final c = _respCompleter;
      _respCompleter = null;
      final txt = utf8.decode(_respBuf, allowMalformed: true);
      _respBuf.clear();
      if (c != null && !c.isCompleted) c.complete(txt);
      return;
    }
    _respBuf.addAll(data);
  }

  void _onMeter(List<int> data) {
    if (data.length < 55) return;
    final bd = ByteData.sublistView(Uint8List.fromList(data));
    final flags = data[20];
    final clipCount = bd.getUint16(21, Endian.little);
    // bit1 flags (DLMS aktif) tidak dipakai: keadaan mode datang dari state.
    _lastRta = List<double>.generate(31, (i) => (data[24 + i] - 60).toDouble());
    _lastMeter = MeterData(
      l: bd.getFloat32(0, Endian.little),
      r: bd.getFloat32(4, Endian.little),
      gr: bd.getFloat32(16, Endian.little),
      clip: clipCount > 0,
      dirty: (flags & 0x01) != 0,
      flt: data[23],
      rta: _lastRta,
    );
    if (!_meterCtl.isClosed) _meterCtl.add(_lastMeter);
  }

  /// Sambungkan GATT, naikkan MTU, temukan karakteristik, dan mulai
  /// berlangganan notifikasi RESP + METER.
  static Future<BleTransport> connectTo(BluetoothDevice device,
      {Duration timeout = const Duration(seconds: 15)}) async {
    final t = BleTransport._(device);
    await t._open(timeout);
    return t;
  }

  Future<void> _open(Duration timeout) async {
    await device.connect(timeout: timeout, autoConnect: false);
    try {
      await device.requestMtu(512);
    } catch (_) {/* platform tanpa requestMtu: lanjut dengan MTU bawaan */}
    final services = await device.discoverServices();
    for (final s in services) {
      if (s.uuid != serviceUuid) continue;
      for (final c in s.characteristics) {
        if (c.uuid == cmdUuid) _cmd = c;
        if (c.uuid == respUuid) _resp = c;
        if (c.uuid == meterUuid) _meter = c;
      }
    }
    if (_cmd == null || _resp == null || _meter == null) {
      try {
        await device.disconnect();
      } catch (_) {}
      throw Exception('Karakteristik BLE S3 Air tidak lengkap');
    }
    _respSub = _resp!.onValueReceived.listen(_onResp);
    _meterSub = _meter!.onValueReceived.listen(_onMeter);
    await _resp!.setNotifyValue(true);
    await _meter!.setNotifyValue(true);
  }

  /// Tulis satu baris perintah dan tunggu jawaban lengkapnya.
  Future<String> _request(String line) {
    return _serialized(() async {
      final completer = Completer<String>();
      _respCompleter = completer;
      _respBuf.clear();
      try {
        await _cmd!.write(utf8.encode('$line\n'), withoutResponse: false);
        return await completer.future.timeout(const Duration(seconds: 5));
      } finally {
        if (identical(_respCompleter, completer)) _respCompleter = null;
      }
    });
  }

  /// Tulis perintah tanpa menunggu jawaban (perintah wifi: alat mulai
  /// ulang, jawaban mungkin tidak pernah tiba — tulisan sukses = sukses).
  Future<void> _writeOnly(String line) {
    return _serialized(() async {
      final c = _respCompleter;
      _respCompleter = null;
      if (c != null && !c.isCompleted) {
        c.completeError(Exception('BLE: koneksi ditutup'));
      }
      await _cmd!.write(utf8.encode('$line\n'), withoutResponse: false);
    });
  }

  void _checkOk(String txt) {
    Map<String, dynamic> j;
    try {
      j = jsonDecode(txt) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('BLE: jawaban alat tidak dikenal');
    }
    if (j['ok'] != 1) throw Exception('BLE: alat menolak perintah');
  }

  @override
  Stream<MeterData>? get meterPush => _meterCtl.stream;

  @override
  Future<DspState> fetchState() async {
    final txt = await _request('state');
    return DspState.fromJson(jsonDecode(txt) as Map<String, dynamic>);
  }

  @override
  Future<MeterData> fetchMeter() async => _lastMeter;

  @override
  Future<List<double>> fetchRta() async => _lastRta;

  /// Pecah isi "set" menjadi beberapa baris <= 500 byte UTF-8
  /// ("set " + isi + '\n'); kunci-kunci saling bebas, urutan tak masalah.
  List<String> _setChunks(Map<String, String> kv) {
    final chunks = <String>[];
    var cur = '';
    for (final e in kv.entries) {
      final part =
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}';
      final candidate = cur.isEmpty ? part : '$cur&$part';
      if (cur.isNotEmpty && utf8.encode('set $candidate\n').length > 500) {
        chunks.add(cur);
        cur = part;
      } else {
        cur = candidate;
      }
    }
    if (cur.isNotEmpty) chunks.add(cur);
    return chunks;
  }

  @override
  Future<void> setParams(Map<String, String> kv) async {
    if (kv.isEmpty) return;
    for (final body in _setChunks(kv)) {
      _checkOk(await _request('set $body'));
    }
  }

  @override
  Future<void> loadPreset(String name) async {
    _checkOk(await _request('preset $name'));
  }

  @override
  Future<void> saveSlot(int slot) async {
    _checkOk(await _request('save $slot'));
  }

  @override
  Future<void> postWifi(String ssid, String pass) async {
    await _writeOnly('wifi $ssid\t$pass');
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final c = _respCompleter;
    _respCompleter = null;
    if (c != null && !c.isCompleted) {
      c.completeError(Exception('BLE: koneksi ditutup'));
    }
    await _respSub?.cancel();
    await _meterSub?.cancel();
    _respSub = null;
    _meterSub = null;
    try {
      await _resp?.setNotifyValue(false);
    } catch (_) {}
    try {
      await _meter?.setNotifyValue(false);
    } catch (_) {}
    try {
      await device.disconnect();
    } catch (_) {}
    await _meterCtl.close();
  }
}

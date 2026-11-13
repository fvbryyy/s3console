// Pengendali alat: memegang state, menjalankan polling meter/RTA (gabungan
// 150 ms sejak firmware v5.2.4; fallback 200+150 ms di firmware lama) seperti
// panel web (200/150 ms), dan meneruskan perubahan ke /api/set.
// Nilai yang sedang diseret diterapkan setempat lebih dulu (terasa seketika),
// pengiriman ke alat di-throttle ±30 ms selama seretan.
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_api.dart';
import 'models.dart';

class DeviceController extends ChangeNotifier {
  DeviceApi? _api;
  DspState? state;
  MeterData meter = const MeterData();
  List<double> rta = const [];
  bool connected = false;
  bool connecting = false;
  String? lastError;
  String host = 'mbahdac.local';
  int selectedBand = 0;

  Timer? _meterTimer, _rtaTimer;
  final Map<String, Timer> _throttle = {};
  final Map<String, Map<String, String>> _pending = {};

  Future<bool> connect(String h) async {
    host = h.trim().isEmpty ? 'mbahdac.local' : h.trim();
    connecting = true;
    lastError = null;
    notifyListeners();
    _api = DeviceApi(host);
    try {
      state = await _api!.fetchState();
      connected = true;
      // Ingat alat ini: buka berikutnya langsung menyambung (rancangan layar 0).
      SharedPreferences.getInstance()
          .then((p) => p.setString('s3host', host))
          .catchError((_) => false);
      connecting = false;
      _startPolling();
      notifyListeners();
      return true;
    } catch (e) {
      connecting = false;
      connected = false;
      lastError = 'Tidak bisa menjangkau $host — pastikan satu WiFi dengan alat.';
      notifyListeners();
      return false;
    }
  }

  /// Muat host yang diingat dari sambungan terakhir (bila ada).
  Future<void> loadSavedHost() async {
    try {
      final p = await SharedPreferences.getInstance();
      final h = p.getString('s3host');
      if (h != null && h.trim().isNotEmpty) host = h.trim();
    } catch (_) {}
  }

  /// Picu gambar ulang dari luar (mis. pilihan band di layar EQ) tanpa
  /// memanggil notifyListeners yang terproteksi.
  void touch() => notifyListeners();

  /// Ganti jaringan WiFi alat. Alat mulai ulang ke jaringan baru, jadi
  /// koneksi ini pasti putus — akhiri setempat dengan disconnect().
  Future<bool> setWifi(String ssid, String pass) async {
    if (_api == null) return false;
    try {
      await _api!.postWifi(ssid.trim(), pass);
      disconnect();
      return true;
    } catch (_) {
      return false;
    }
  }

  void disconnect() {
    _stopPolling();
    connected = false;
    notifyListeners();
  }

  bool _meterBusy = false, _rtaBusy = false;

  void _startPolling() {
    _stopPolling();
    // Penjaga in-flight: jangan menumpuk permintaan baru selama yang lama
    // belum pulang — penumpukan di server ESP + antrean koneksi peramban
    // membuat meter terlihat "mati lalu hidup" (beku lama, lalu meloncat).
    _meterTimer = Timer.periodic(const Duration(milliseconds: 150), (_) async {
      if (_meterBusy) return;
      _meterBusy = true;
      try {
        _meterTgt = await _api!.fetchMeter();
        if (state != null && state!.dirty != _meterTgt.dirty) {
          state!.dirty = _meterTgt.dirty;
        }
        // Firmware v5.2.4+: RTA datang sekalian dalam respons meter ->
        // matikan polling /api/rta terpisah (permintaan ke alat turun
        // dari +-12/detik menjadi +-7/detik). Firmware lama: bidang rta
        // kosong, timer RTA tetap berjalan seperti biasa.
        final rt = _meterTgt.rta;
        if (rt != null && rt.length >= 31) {
          _rtaTgt = rt;
          if (rta.length != 31) rta = List.of(rt);
          if (_rtaTimer != null) {
            _rtaTimer!.cancel();
            _rtaTimer = null;
          }
        }
      } catch (_) {/* abaikan sesaat; putus total ditangani reconnect manual */}
      _meterBusy = false;
    });
    _rtaTimer = Timer.periodic(const Duration(milliseconds: 150), (_) async {
      if (_rtaBusy) return;
      _rtaBusy = true;
      try {
        _rtaTgt = await _api!.fetchRta();
        if (rta.length != 31 && _rtaTgt.length >= 31) {
          rta = List.of(_rtaTgt); // jepret pertama: langsung penuh
        }
      } catch (_) {}
      _rtaBusy = false;
    });
    // Animasi tampilan 50 ms — peniru panel web asli: panel mengambil data
    // pada laju yang sama (meter 200 ms, RTA 150 ms) tapi MENGGAMBAR tiap
    // 50 ms dengan nilai yang dilicinkan (attack 0,55 / release 0,16),
    // jadi gerakannya mengalir. Aplikasi dulu menggambar nilai mentah
    // seirama polling -> patah-patah dan terasa "lag / kayak ga nyambung"
    // (koreksi user 2026-11-13 20:32, terbukti dari sumber panel).
    _animTimer =
        Timer.periodic(const Duration(milliseconds: 50), (_) => _animTick());
  }

  MeterData _meterTgt = const MeterData();
  List<double> _rtaTgt = const [];
  Timer? _animTimer;

  void _animTick() {
    var changed = false;
    double ease(double cur, double tgt, double up, double down) {
      final d = tgt - cur;
      if (d.abs() < 0.0005) return cur;
      changed = true;
      return cur + d * (d > 0 ? up : down);
    }

    final nl = ease(meter.l, _meterTgt.l, 0.6, 0.12);
    final nr = ease(meter.r, _meterTgt.r, 0.6, 0.12);
    final metaChanged = meter.gr != _meterTgt.gr ||
        meter.clip != _meterTgt.clip ||
        meter.dirty != _meterTgt.dirty ||
        meter.flt != _meterTgt.flt;
    if (changed || metaChanged) {
      meter = MeterData(
        l: nl,
        r: nr,
        gr: _meterTgt.gr,
        clip: _meterTgt.clip,
        dirty: _meterTgt.dirty,
        flt: _meterTgt.flt,
      );
      changed = true;
    }
    if (rta.length >= 31 && _rtaTgt.length >= 31) {
      for (var i = 0; i < 31; i++) {
        final d = _rtaTgt[i] - rta[i];
        if (d.abs() > 0.05) {
          rta[i] += d * (d > 0 ? 0.55 : 0.16);
          changed = true;
        }
      }
    }
    if (changed) notifyListeners();
  }

  void _stopPolling() {
    _meterTimer?.cancel();
    _rtaTimer?.cancel();
    _animTimer?.cancel();
    _meterTimer = null;
    _rtaTimer = null;
    _animTimer = null;
  }

  /// Kirim seketika (tombol, saklar, nilai akhir seretan).
  Future<void> sendNow(Map<String, String> kv) async {
    if (_api == null) return;
    try {
      await _api!.setParams(kv);
    } catch (_) {}
    if (state != null && !state!.dirty) {
      state!.dirty = true; // alat akan mengonfirmasi lewat meter
      notifyListeners();
    }
  }

  /// Kirim ter-throttle untuk seretan berkelanjutan (fader, titik grafik).
  void sendDrag(String group, Map<String, String> kv) {
    _pending[group] = kv;
    if (_throttle.containsKey(group)) return;
    _throttle[group] = Timer(const Duration(milliseconds: 30), () {
      _throttle.remove(group);
      final p = _pending.remove(group);
      if (p != null) sendNow(p);
    });
    // kirim nilai pertama langsung agar tidak terasa tertunda
    final first = _pending[group];
    if (first != null) {
      _pending.remove(group);
      sendNow(first);
    }
  }

  // ---- perubahan setempat + kirim -------------------------------------------

  void setBandGain(int i, double g, {bool drag = false}) {
    final s = state;
    if (s == null || i < 0 || i >= s.bands.length) return;
    s.bands[i].g = g.clamp(-15, 15).toDouble();
    notifyListeners();
    final kv = {'b${i}_g': s.bands[i].g.toStringAsFixed(2)};
    drag ? sendDrag('band$i', kv) : sendNow(kv);
  }

  void setBandFreqGain(int i, double f, double g, {bool drag = false}) {
    final s = state;
    if (s == null || i < 0 || i >= s.bands.length) return;
    final b = s.bands[i];
    b.f = f.clamp(20, 20000).toDouble();
    b.g = g.clamp(-15, 15).toDouble();
    notifyListeners();
    final kv = {
      'b${i}_f': b.f.toStringAsFixed(1),
      'b${i}_g': b.g.toStringAsFixed(2),
    };
    drag ? sendDrag('band$i', kv) : sendNow(kv);
  }

  void setBandField(int i, String field, String value) {
    final s = state;
    if (s == null || i < 0 || i >= s.bands.length) return;
    final b = s.bands[i];
    final v = double.tryParse(value) ?? 0;
    switch (field) {
      case 'f':
        b.f = v.clamp(20, 20000).toDouble();
        break;
      case 'g':
        b.g = v.clamp(-15, 15).toDouble();
        break;
      case 'q':
        b.q = v.clamp(0.4, 10).toDouble();
        break;
      case 't':
        b.t = v.toInt();
        break;
      case 'on':
        b.on = v != 0;
        break;
    }
    notifyListeners();
    sendNow({'b${i}_$field': value});
  }

  void setVolDb(double db, {bool drag = false}) {
    final s = state;
    if (s == null) return;
    final c = db.clamp(-60, 0).toDouble();
    s.vol = math.pow(10, c / 20).toDouble().clamp(0.0, 1.0).toDouble();
    notifyListeners();
    final kv = {'vol': s.vol.toStringAsFixed(4)};
    drag ? sendDrag('vol', kv) : sendNow(kv);
  }

  double get volDb {
    final s = state;
    if (s == null || s.vol <= 0.0009) return -60;
    return (20 * math.log(s.vol) / math.ln10).clamp(-60, 0).toDouble();
  }

  void setMute(bool m) {
    final s = state;
    if (s == null) return;
    s.mute = m;
    notifyListeners();
    sendNow({'mute': m ? '1' : '0'});
  }

  void setDim(bool on) {
    final s = state;
    if (s == null) return;
    s.dim = on;
    notifyListeners();
    sendNow({'dim': on ? '1' : '0'});
  }

  void setDlmsOn(bool on) {
    final s = state;
    if (s == null) return;
    s.dlms.on = on;
    notifyListeners();
    sendNow({'dlmsOn': on ? '1' : '0'});
  }

  Future<void> saveAll() async {
    await sendNow({'saveState': '1'});
    // titik padam dikonfirmasi meter; paksa setempat juga
    if (state != null) {
      state!.dirty = false;
      notifyListeners();
    }
  }

  String lastPreset = '—';

  /// Penyetel umum parameter reguler: perbarui setempat + kirim /api/set.
  /// Kunci boolean dikirim '1'/'0' (value 0/1). Seretan di-throttle per kunci.
  void setParam(String key, double value, {bool drag = false}) {
    final s = state;
    if (s == null) return;
    final b = value != 0;
    switch (key) {
      case 'preamp':
        s.preamp = value;
        break;
      case 'trimL':
        s.trimL = value;
        break;
      case 'trimR':
        s.trimR = value;
        break;
      case 'polL':
        s.polL = b;
        break;
      case 'polR':
        s.polR = b;
        break;
      case 'bypass':
        s.bypass = b;
        break;
      case 'hpfOn':
        s.hpfOn = b;
        break;
      case 'hpfFreq':
        s.hpfFreq = value;
        break;
      case 'hpfSlope':
        s.hpfSlope = value.toInt();
        break;
      case 'eqMode':
        s.eqMode = value.toInt();
        break;
      case 'loud':
        s.loud = b;
        break;
      case 'autoHr':
        s.autoHr = b;
        break;
      case 'gateOn':
        s.gateOn = b;
        break;
      case 'gateThr':
        s.gateThr = value;
        break;
      case 'gateAtk':
        s.gateAtk = value;
        break;
      case 'gateRel':
        s.gateRel = value;
        break;
      case 'compOn':
        s.compOn = b;
        break;
      case 'compThr':
        s.compThr = value;
        break;
      case 'compRatio':
        s.compRatio = value;
        break;
      case 'compAtk':
        s.compAtk = value;
        break;
      case 'compRel':
        s.compRel = value;
        break;
      case 'compMake':
        s.compMake = value;
        break;
      case 'limiter':
        s.limiter = b;
        break;
      case 'ceiling':
        s.ceiling = value;
        break;
      case 'xfOn':
        s.xfOn = b;
        break;
      case 'xfAmt':
        s.xfAmt = value;
        break;
      case 'width':
        s.width = value;
        break;
      case 'balance':
        s.balance = value;
        break;
      case 'mono':
        s.mono = b;
        break;
      case 'dlyL':
        s.dlyL = value;
        break;
      case 'dlyR':
        s.dlyR = value;
        break;
      case 'volMax':
        s.volMax = value;
        break;
      case 'autosave':
        s.autosave = b;
        break;
    }
    notifyListeners();
    final isBool = const {
      'polL', 'polR', 'bypass', 'hpfOn', 'loud', 'autoHr', 'gateOn', 'compOn',
      'limiter', 'xfOn', 'mono', 'autosave'
    }.contains(key);
    final kv = {key: isBool ? (b ? '1' : '0') : value.toStringAsFixed(2)};
    drag ? sendDrag('p_$key', kv) : sendNow(kv);
  }

  Future<void> loadPreset(String name, String label) async {
    if (_api == null) return;
    try {
      await _api!.loadPreset(name);
      lastPreset = label;
      await refreshState();
    } catch (_) {}
  }

  Future<void> saveToSlot(int slot) async {
    if (_api == null) return;
    try {
      await _api!.saveSlot(slot);
      await refreshState();
    } catch (_) {}
  }

  // ---- DLMS -----------------------------------------------------------------

  void setInGain(bool isA, double db, {bool drag = false}) {
    final s = state;
    if (s == null) return;
    final v = db.clamp(-60, 12).toDouble();
    if (isA) {
      s.dlms.inGainA = v;
    } else {
      s.dlms.inGainB = v;
    }
    notifyListeners();
    final kv = {isA ? 'inGainA' : 'inGainB': v.toStringAsFixed(2)};
    drag ? sendDrag(isA ? 'inA' : 'inB', kv) : sendNow(kv);
  }

  void setInOn(bool isA, bool on) {
    final s = state;
    if (s == null) return;
    if (isA) {
      s.dlms.inOnA = on;
    } else {
      s.dlms.inOnB = on;
    }
    notifyListeners();
    sendNow({isA ? 'inOnA' : 'inOnB': on ? '1' : '0'});
  }

  void setInDelay(bool isA, double ms, {bool drag = false}) {
    final s = state;
    if (s == null) return;
    final v = ms.clamp(0, 100).toDouble();
    if (isA) {
      s.dlms.inDlyA = v;
    } else {
      s.dlms.inDlyB = v;
    }
    notifyListeners();
    final kv = {isA ? 'inDlyA' : 'inDlyB': v.toStringAsFixed(2)};
    drag ? sendDrag(isA ? 'inDlyA' : 'inDlyB', kv) : sendNow(kv);
  }

  void setChGain(int ch, double db, {bool drag = false}) {
    final s = state;
    if (s == null || ch < 0 || ch >= s.dlms.ch.length) return;
    final v = db.clamp(-60, 12).toDouble();
    s.dlms.ch[ch].gain = v;
    notifyListeners();
    final kv = {'c${ch}_gain': v.toStringAsFixed(2)};
    drag ? sendDrag('ch$ch', kv) : sendNow(kv);
  }

  void setChOn(int ch, bool on) {
    final s = state;
    if (s == null || ch < 0 || ch >= s.dlms.ch.length) return;
    s.dlms.ch[ch].on = on;
    notifyListeners();
    sendNow({'c${ch}_on': on ? '1' : '0'});
  }

  void setChPeqGain(int ch, int band, double db, {bool drag = false}) {
    final s = state;
    if (s == null || ch < 0 || ch >= s.dlms.ch.length) return;
    final v = db.clamp(-15, 15).toDouble();
    s.dlms.ch[ch].peq[band] = v;
    notifyListeners();
    final kv = {'c${ch}_p$band': v.toStringAsFixed(2)};
    drag ? sendDrag('ch${ch}p$band', kv) : sendNow(kv);
  }

  /// Bidang DLMS lain (routing/crossover/delay/limiter/fase);
  /// nilai setempat diperbarui seperlunya, seretan di-throttle per bidang.
  void setChField(int ch, String field, String value, {bool drag = false}) {
    final s = state;
    if (s == null || ch < 0 || ch >= s.dlms.ch.length) return;
    final c = s.dlms.ch[ch];
    final v = double.tryParse(value) ?? 0;
    switch (field) {
      case 'src':
        c.src = v.toInt();
        break;
      case 'hpfOn':
        c.hpfOn = v != 0;
        break;
      case 'hpfF':
        c.hpfF = v;
        break;
      case 'lpfOn':
        c.lpfOn = v != 0;
        break;
      case 'lpfF':
        c.lpfF = v;
        break;
      case 'tf':
        c.tf = v.toInt();
        break;
      case 'peqOn':
        c.peqOn = v != 0;
        break;
      case 'gain':
        c.gain = v;
        break;
      case 'dly':
        c.dly = v;
        break;
      case 'lim':
        c.lim = v;
        break;
      case 'pol':
        c.pol = v != 0;
        break;
    }
    notifyListeners();
    final kv = {'c${ch}_$field': value};
    drag ? sendDrag('ch${ch}_$field', kv) : sendNow(kv);
  }

  Future<void> refreshState() async {
    if (_api == null) return;
    try {
      state = await _api!.fetchState();
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _stopPolling();
    for (final t in _throttle.values) {
      t.cancel();
    }
    super.dispose();
  }
}

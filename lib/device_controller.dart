// Pengendali alat: memegang state, menjalankan polling meter/RTA seperti
// panel web (200/150 ms), dan meneruskan perubahan ke /api/set.
// Nilai yang sedang diseret diterapkan setempat lebih dulu (terasa seketika),
// pengiriman ke alat di-throttle ±30 ms selama seretan.
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
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

  void disconnect() {
    _stopPolling();
    connected = false;
    notifyListeners();
  }

  void _startPolling() {
    _stopPolling();
    _meterTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      try {
        meter = await _api!.fetchMeter();
        if (state != null && state!.dirty != meter.dirty) {
          state!.dirty = meter.dirty;
        }
        notifyListeners();
      } catch (_) {/* abaikan sesaat; putus total ditangani reconnect manual */}
    });
    _rtaTimer = Timer.periodic(const Duration(milliseconds: 150), (_) async {
      try {
        rta = await _api!.fetchRta();
        notifyListeners();
      } catch (_) {}
    });
  }

  void _stopPolling() {
    _meterTimer?.cancel();
    _rtaTimer?.cancel();
    _meterTimer = null;
    _rtaTimer = null;
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

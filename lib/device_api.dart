// Transport WiFi ke API firmware S3 Air — pintu yang sama dengan panel web:
// GET /api/state, /api/meter, /api/rta dan POST /api/set (form-urlencoded).
// Meter diambil dengan polling oleh pengendali (meterPush null).
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'device_transport.dart';
import 'models.dart';

class DeviceApi implements DeviceTransport {
  String host;
  DeviceApi(this.host);

  @override
  Stream<MeterData>? get meterPush => null;

  @override
  Future<void> close() async {} // tidak ada koneksi menetap yang dipegang

  Uri _u(String path) => Uri.parse('http://$host$path');

  @override
  Future<DspState> fetchState() async {
    final r = await http.get(_u('/api/state')).timeout(const Duration(seconds: 4));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    return DspState.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  @override
  Future<MeterData> fetchMeter() async {
    final r = await http.get(_u('/api/meter')).timeout(const Duration(seconds: 1));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    return MeterData.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  @override
  Future<List<double>> fetchRta() async {
    final r = await http.get(_u('/api/rta')).timeout(const Duration(seconds: 1));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return (j['rta'] as List? ?? const []).map((e) => (e as num).toDouble()).toList();
  }

  @override
  Future<void> setParams(Map<String, String> kv) async {
    final r = await http
        .post(_u('/api/set'), body: kv)
        .timeout(const Duration(seconds: 3));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
  }

  /// Muat preset: name = 'flat'|'speaker'|'vokal'|'bass'|'malam' atau 'user:<i>'.
  @override
  Future<void> loadPreset(String name) async {
    final r = await http
        .post(_u('/api/preset'), body: {'name': name})
        .timeout(const Duration(seconds: 3));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
  }

  /// Ganti kredensial WiFi alat; alat mulai ulang ke jaringan baru.
  @override
  Future<void> postWifi(String ssid, String pass) async {
    final r = await http
        .post(_u('/api/wifi'), body: {'ssid': ssid, 'pass': pass})
        .timeout(const Duration(seconds: 4));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
  }

  /// Simpan keadaan sekarang ke slot user (0-based).
  @override
  Future<void> saveSlot(int slot) async {
    final r = await http
        .post(_u('/api/save'), body: {'slot': '$slot'})
        .timeout(const Duration(seconds: 3));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
  }
}

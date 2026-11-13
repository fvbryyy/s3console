// Transport WiFi ke API firmware S3 Air — pintu yang sama dengan panel web:
// GET /api/state, /api/meter, /api/rta dan POST /api/set (form-urlencoded).
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class DeviceApi {
  String host;
  DeviceApi(this.host);

  Uri _u(String path) => Uri.parse('http://$host$path');

  Future<DspState> fetchState() async {
    final r = await http.get(_u('/api/state')).timeout(const Duration(seconds: 4));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    return DspState.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<MeterData> fetchMeter() async {
    final r = await http.get(_u('/api/meter')).timeout(const Duration(seconds: 1));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    return MeterData.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<List<double>> fetchRta() async {
    final r = await http.get(_u('/api/rta')).timeout(const Duration(seconds: 1));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return (j['rta'] as List? ?? const []).map((e) => (e as num).toDouble()).toList();
  }

  Future<void> setParams(Map<String, String> kv) async {
    final r = await http
        .post(_u('/api/set'), body: kv)
        .timeout(const Duration(seconds: 3));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
  }

  /// Muat preset: name = 'flat'|'speaker'|'vokal'|'bass'|'malam' atau 'user:<i>'.
  Future<void> loadPreset(String name) async {
    final r = await http
        .post(_u('/api/preset'), body: {'name': name})
        .timeout(const Duration(seconds: 3));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
  }

  /// Simpan keadaan sekarang ke slot user (0-based).
  Future<void> saveSlot(int slot) async {
    final r = await http
        .post(_u('/api/save'), body: {'slot': '$slot'})
        .timeout(const Duration(seconds: 3));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
  }
}

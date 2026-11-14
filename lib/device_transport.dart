// Antarmuka transport ke alat S3 Air. Dua perwujudan:
// - DeviceApi (device_api.dart): HTTP/WiFi ke API firmware — meter di-polling.
// - BleTransport (device_ble.dart): Bluetooth LE — meter didorong alat
//   lewat notifikasi, jadi [meterPush] tidak null di sana.
// Pengendali (DeviceController) hanya berbicara lewat antarmuka ini.
import 'models.dart';

abstract class DeviceTransport {
  /// Keadaan penuh alat (skema sama dengan GET /api/state).
  Future<DspState> fetchState();

  /// Cuplikan meter terakhir (dipakai jalur polling HTTP).
  Future<MeterData> fetchMeter();

  /// RTA 31 band (dipakai jalur polling HTTP pada firmware lama).
  Future<List<double>> fetchRta();

  /// Aliran meter dorongan (meter + RTA dalam satu paket) — hanya untuk
  /// transport yang mendorong (BLE). Null = pengendali memakai polling.
  Stream<MeterData>? get meterPush;

  /// Terapkan parameter (kunci/nilai persis seperti POST /api/set).
  Future<void> setParams(Map<String, String> kv);

  /// Muat preset: name = 'flat'|'speaker'|'vokal'|'bass'|'malam'|'user:<i>'.
  Future<void> loadPreset(String name);

  /// Simpan keadaan sekarang ke slot user (0-based).
  Future<void> saveSlot(int slot);

  /// Ganti kredensial WiFi alat; alat mulai ulang ke jaringan baru.
  Future<void> postWifi(String ssid, String pass);

  /// Tutup transport dan bebaskan sumber dayanya.
  Future<void> close();
}

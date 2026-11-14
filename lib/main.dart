// S3 Air — konsol DSP (aplikasi pendamping ESP32-S3 + PCM5102).
// Struktur mengikuti rancangan v22: header (logo, tab CHANNEL/EQ/RTA/PRESET/
// PENGATURAN/INFO, status Terhubung, saklar DLMS|REGULER), baris preset +
// SIMPAN, lalu isi tab. Berbicara ke API firmware yang sama dengan panel web.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'channel_screen.dart';
import 'device_ble.dart';
import 'device_controller.dart';
import 'eq_screen.dart';
import 'regular_channel.dart';
import 'rta_screen.dart';
import 'tabs_misc.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const S3App());
}

class S3App extends StatefulWidget {
  const S3App({super.key});
  @override
  State<S3App> createState() => _S3AppState();
}

class _S3AppState extends State<S3App> {
  final ctl = DeviceController();

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S3 Air',
      debugShowCheckedModeBanner: false,
      theme: buildS3Theme(),
      home: AnimatedBuilder(
        animation: ctl,
        builder: (context, _) =>
            ctl.connected ? ConsoleScreen(ctl: ctl) : ConnectScreen(ctl: ctl),
      ),
    );
  }
}

// --- Layar sambut (rancangan layar 0) ----------------------------------------

class ConnectScreen extends StatefulWidget {
  final DeviceController ctl;
  const ConnectScreen({super.key, required this.ctl});
  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  late final TextEditingController hostCtl =
      TextEditingController(text: widget.ctl.host);
  bool triedAuto = false;
  bool _bleBusy = false;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Alur tombol BLUETOOTH: pastikan adaptor menyala, pindai alat
  /// "S3 Air", tampilkan daftar, sambungkan pilihan user. Pasangan
  /// pertama memunculkan dialog pairing dari sistem — itu wajar; alat
  /// hanya menerima ikatan baru selama jendela pairing-nya terbuka.
  Future<void> _bluetoothFlow() async {
    if (_bleBusy || widget.ctl.connecting) return;
    setState(() => _bleBusy = true);
    try {
      var supported = false;
      try {
        supported = await FlutterBluePlus.isSupported;
      } catch (_) {}
      if (!supported) {
        _snack('HP ini tidak mendukung Bluetooth LE.');
        return;
      }
      if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
        _snack('Aktifkan Bluetooth dulu, lalu ketuk BLUETOOTH lagi.');
        return;
      }
      if (!mounted) return;
      final picked = await showDialog<BluetoothDevice>(
        context: context,
        builder: (c) => const _BleScanDialog(),
      );
      if (picked == null || !mounted) return;
      final ok = await widget.ctl.connectBle(picked);
      if (!ok) {
        _snack('Sambungan Bluetooth gagal. Untuk pasangan pertama, alat '
            'hanya menerima ikatan baru selama 60 detik sesudah menyala '
            'atau sesudah tombol BOOT ditekan — coba lagi dalam jendela itu.');
      }
    } catch (_) {
      _snack('Bluetooth gagal dibuka — periksa izin Bluetooth/lokasi '
          'untuk aplikasi ini di Pengaturan HP.');
    } finally {
      if (mounted) setState(() => _bleBusy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!triedAuto) {
        triedAuto = true;
        await widget.ctl.loadSavedHost();
        if (mounted) hostCtl.text = widget.ctl.host;
        final ok = await widget.ctl.connect(hostCtl.text);
        if (!ok && mounted) {
          // WiFi tak terjangkau: coba alat Bluetooth yang diingat.
          await widget.ctl.tryConnectSavedBle();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctl = widget.ctl;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: S3Colors.meterGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Text('S3 AIR',
                                style: TextStyle(
                                    fontSize: 62,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text('USB DAC & DLMS Console',
                            style: TextStyle(
                                color: S3Colors.accb, fontSize: 19)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Center(
                    child: Container(
                      width: 380,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: S3Colors.panel,
                        border: Border.all(color: S3Colors.line),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 11,
                                height: 11,
                                decoration: const BoxDecoration(
                                  color: S3Colors.meterGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Alat ditemukan di jaringan',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: S3Colors.card,
                              border: Border.all(color: S3Colors.line),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('S3 Air — mbahdac.local',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 3),
                                Text(
                                  '${hostCtl.text}  ·  Firmware ${ctl.state?.fw.isNotEmpty == true ? ctl.state!.fw : '—'}',
                                  style: const TextStyle(color: S3Colors.dim),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: hostCtl,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Alamat alat (nama .local atau IP)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          if (ctl.lastError != null) ...[
                            const SizedBox(height: 8),
                            Text(ctl.lastError!,
                                style: const TextStyle(color: S3Colors.red)),
                          ],
                          const SizedBox(height: 14),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: S3Colors.green,
                              foregroundColor: S3Colors.accDark,
                              elevation: 6,
                              shadowColor: S3Colors.green,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15),
                            ),
                            onPressed: ctl.connecting
                                ? null
                                : () => ctl.connect(hostCtl.text),
                            child: Text(
                              ctl.connecting ? 'MENYAMBUNG…' : 'HUBUNGKAN',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      setState(() => hostCtl.text = '192.168.1.26'),
                                  child: const Text('IP MANUAL'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: (_bleBusy || ctl.connecting)
                                      ? null
                                      : _bluetoothFlow,
                                  child: Text(
                                      _bleBusy ? 'MEMINDAI…' : 'BLUETOOTH',
                                      style: const TextStyle(
                                          color: Color(0xFF6ED0E4))),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'WiFi untuk di rumah — Bluetooth untuk di lapangan (jarak dekat).\nSaat memakai WiFi, pastikan HP satu jaringan dengan alat.',
                            style: TextStyle(color: S3Colors.dim, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Positioned(
              left: 18,
              bottom: 12,
              child: Text('Developed by bryyy',
                  style: TextStyle(color: S3Colors.dim, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Konsol -------------------------------------------------------------------

class ConsoleScreen extends StatefulWidget {
  final DeviceController ctl;
  const ConsoleScreen({super.key, required this.ctl});
  @override
  State<ConsoleScreen> createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends State<ConsoleScreen> {
  static const tabs = ['CHANNEL', 'EQ', 'RTA', 'PRESET', 'PENGATURAN', 'INFO'];
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final ctl = widget.ctl;
    final s = ctl.state!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(ctl, s),
            _subbar(ctl, s),
            Expanded(child: _body(ctl, s)),
          ],
        ),
      ),
    );
  }

  Widget _header(DeviceController ctl, dynamic s) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: S3Colors.bg,
        border: Border(bottom: BorderSide(color: S3Colors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 13,
            height: 13,
            decoration: const BoxDecoration(
              color: S3Colors.meterGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text('S3 AIR',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(width: 18),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Material(
                        color: i == tab ? S3Colors.blue : Colors.transparent,
                        elevation: i == tab ? 5 : 0,
                        shadowColor: S3Colors.blue,
                        borderRadius: BorderRadius.circular(7),
                        child: InkWell(
                          onTap: () => setState(() => tab = i),
                          borderRadius: BorderRadius.circular(7),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Text(
                              tabs[i],
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: i == tab ? Colors.white : S3Colors.dim,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text('Terhubung',
              style: TextStyle(color: S3Colors.accb, fontSize: 13)),
          const SizedBox(width: 10),
          // saklar mode: DLMS hijau saat aktif, REGULER slate saat aktif
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _modeSeg('DLMS', s.dlms.on, true, () => ctl.setDlmsOn(true)),
              const SizedBox(width: 4),
              _modeSeg('REGULER', !s.dlms.on, false, () => ctl.setDlmsOn(false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeSeg(String label, bool active, bool isDlms, VoidCallback onTap) {
    final bg = active
        ? (isDlms ? S3Colors.green : S3Colors.slate)
        : S3Colors.card;
    final fg = active
        ? (isDlms ? S3Colors.accDark : Colors.white)
        : S3Colors.dim;
    return Material(
      color: bg,
      elevation: active ? 5 : 1.5,
      shadowColor: active ? bg : Colors.black,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.bold, color: fg)),
        ),
      ),
    );
  }

  Widget _subbar(DeviceController ctl, dynamic s) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text('Preset: ${ctl.lastPreset}',
              style: TextStyle(color: S3Colors.dim, fontSize: 12.5)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ctl.meter.clip ? S3Colors.muteRed : S3Colors.card,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('CLIP',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: ctl.meter.clip ? Colors.white : S3Colors.dim)),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: 30,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: S3Colors.blue,
                    elevation: 4,
                    shadowColor: S3Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: () => ctl.saveAll(),
                  child: const Text('SIMPAN', style: TextStyle(fontSize: 12.5)),
                ),
              ),
              if (s.dirty)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: S3Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body(DeviceController ctl, dynamic s) {
    switch (tabs[tab]) {
      case 'CHANNEL':
        return s.dlms.on
            ? ChannelScreen(ctl: ctl)
            : RegularChannelScreen(ctl: ctl);
      case 'EQ':
        return EqScreen(ctl: ctl, onOpenDlms: () => setState(() => tab = 0));
      case 'RTA':
        return RtaScreen(ctl: ctl);
      case 'PRESET':
        return PresetScreen(ctl: ctl);
      case 'PENGATURAN':
        return PengaturanScreen(ctl: ctl);
      case 'INFO':
        return InfoScreen(ctl: ctl);
      default:
        return const SizedBox.shrink();
    }
  }
}

// --- Dialog pemindaian Bluetooth ----------------------------------------------
// Memindai ±10 detik untuk alat bernama "S3 Air" atau yang mengiklankan
// UUID layanan S3 Air; user mengetuk satu untuk menyambung.

class _BleScanDialog extends StatefulWidget {
  const _BleScanDialog();
  @override
  State<_BleScanDialog> createState() => _BleScanDialogState();
}

class _BleScanDialogState extends State<_BleScanDialog> {
  final Map<String, BluetoothDevice> _found = {};
  StreamSubscription<List<ScanResult>>? _sub;
  Timer? _timer;
  bool _scanning = true;

  @override
  void initState() {
    super.initState();
    _sub = FlutterBluePlus.scanResults.listen((results) {
      var changed = false;
      for (final r in results) {
        final name = r.advertisementData.advName.isNotEmpty
            ? r.advertisementData.advName
            : r.device.platformName;
        final match = name == 'S3 Air' ||
            r.advertisementData.serviceUuids
                .contains(BleTransport.serviceUuid);
        if (match && !_found.containsKey(r.device.remoteId.str)) {
          _found[r.device.remoteId.str] = r.device;
          changed = true;
        }
      }
      if (changed && mounted) setState(() {});
    });
    _timer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _scanning = false);
    });
    unawaited(_runScan());
  }

  Future<void> _runScan() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (_) {/* izin/adaptor: daftar tetap kosong, pesan tampil di dialog */}
    if (mounted && _scanning) setState(() => _scanning = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    unawaited(FlutterBluePlus.stopScan().catchError((_) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _found.values.toList();
    return AlertDialog(
      backgroundColor: S3Colors.panel,
      title: const Text('Pilih alat Bluetooth',
          style: TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_scanning)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Memindai…',
                      style: TextStyle(color: S3Colors.dim, fontSize: 13)),
                ],
              ),
            if (items.isEmpty && !_scanning)
              const Text(
                'Tidak ada alat "S3 Air" yang terlihat. Pastikan alat menyala dan dekat dengan HP.',
                style: TextStyle(color: S3Colors.dim, fontSize: 13),
              ),
            for (final d in items)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('S3 Air',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(d.remoteId.str,
                    style:
                        const TextStyle(color: S3Colors.dim, fontSize: 12)),
                trailing:
                    const Icon(Icons.bluetooth, color: Color(0xFF6ED0E4)),
                onTap: () => Navigator.pop(context, d),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}

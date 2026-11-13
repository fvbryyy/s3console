// S3 Air — konsol DSP (aplikasi pendamping ESP32-S3 + PCM5102).
// Alur: layar sambung -> konsol. Konsol berbicara ke API firmware yang sama
// dengan panel web (mbahdac.local). Tata letak lanskap mengikuti rancangan.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'device_controller.dart';
import 'eq_screen.dart';
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

// -----------------------------------------------------------------------------

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

  @override
  void initState() {
    super.initState();
    // Sekali sambung, aplikasi mengingat alat & mencoba menyambung sendiri.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!triedAuto) {
        triedAuto = true;
        await widget.ctl.connect(hostCtl.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctl = widget.ctl;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // identitas besar di kiri (tanpa teks pemasaran)
            Expanded(
              flex: 5,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2),
                        children: [
                          TextSpan(text: 'S3 ', style: TextStyle(color: S3Colors.txt)),
                          TextSpan(text: 'AIR', style: TextStyle(color: S3Colors.cyan)),
                        ],
                      ),
                    ),
                    const Text('KONSOL DSP',
                        style: TextStyle(
                            color: S3Colors.dim,
                            fontSize: 15,
                            letterSpacing: 6)),
                  ],
                ),
              ),
            ),
            // kartu sambung di kanan
            Expanded(
              flex: 4,
              child: Center(
                child: Container(
                  width: 360,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: S3Colors.panel,
                    border: Border.all(color: S3Colors.line),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Alat ditemukan',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: S3Colors.card,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('S3 Air · mbahdac',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              ctl.state?.fw.isNotEmpty == true
                                  ? 'Firmware ${ctl.state!.fw}'
                                  : 'Konsol DSP ESP32-S3',
                              style: const TextStyle(color: S3Colors.dim),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: hostCtl,
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
                          backgroundColor: S3Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: ctl.connecting
                            ? null
                            : () => ctl.connect(hostCtl.text),
                        child: Text(
                          ctl.connecting ? 'MENYAMBUNG…' : 'HUBUNGKAN',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                hostCtl.text = '192.168.1.26';
                              },
                              child: const Text('IP MANUAL'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: OutlinedButton(
                              onPressed: null, // BLE menyusul sesudah firmware BLE
                              child: Text('BLUETOOTH'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Catatan: HP dan alat harus satu WiFi yang sama.',
                        style: TextStyle(color: S3Colors.dim, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------

class ConsoleScreen extends StatefulWidget {
  final DeviceController ctl;
  const ConsoleScreen({super.key, required this.ctl});
  @override
  State<ConsoleScreen> createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends State<ConsoleScreen> {
  static const tabs = ['EQ', 'Gate', 'Comp', 'Main', 'Preset', 'Sistem', 'DLMS'];
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final ctl = widget.ctl;
    final s = ctl.state!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _navbar(ctl, s),
            Expanded(child: _body(ctl, s)),
          ],
        ),
      ),
    );
  }

  Widget _navbar(DeviceController ctl, dynamic s) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: S3Colors.panel,
        border: Border(bottom: BorderSide(color: S3Colors.line)),
      ),
      child: Row(
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              children: [
                TextSpan(text: 'S3 ', style: TextStyle(color: S3Colors.txt)),
                TextSpan(text: 'AIR', style: TextStyle(color: S3Colors.cyan)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          for (var i = 0; i < tabs.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Material(
                color: i == tab ? S3Colors.blue : S3Colors.card,
                borderRadius: BorderRadius.circular(5),
                child: InkWell(
                  onTap: () => setState(() => tab = i),
                  borderRadius: BorderRadius.circular(5),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: i == tab ? Colors.white : S3Colors.dim,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const Spacer(),
          // lampu CLIP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
          // tombol SIMPAN + titik belum tersimpan
          Stack(
            clipBehavior: Clip.none,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: S3Colors.blue),
                onPressed: () => ctl.saveAll(),
                child: const Text('SIMPAN'),
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
          const SizedBox(width: 12),
          // saklar mode DLMS | REGULER
          Container(
            decoration: BoxDecoration(
              color: S3Colors.card,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _seg('REGULER', !s.dlms.on, () => ctl.setDlmsOn(false)),
                _seg('DLMS', s.dlms.on, () => ctl.setDlmsOn(true)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 9, color: S3Colors.green),
              SizedBox(width: 5),
              Text('Terhubung', style: TextStyle(color: S3Colors.dim)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _seg(String label, bool active, VoidCallback onTap) {
    return Material(
      color: active ? S3Colors.blue : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : S3Colors.dim)),
        ),
      ),
    );
  }

  Widget _body(DeviceController ctl, dynamic s) {
    switch (tabs[tab]) {
      case 'EQ':
        return EqScreen(ctl: ctl, onOpenDlms: () => setState(() => tab = 6));
      case 'DLMS':
        return _placeholder(
            'Tab DLMS — layar input A/B, routing, crossover, delay, limiter per OUT menyusul di increment berikutnya. Untuk sementara atur DLMS dari panel web (mbahdac.local).');
      default:
        return _placeholder(
            'Tab ${tabs[tab]} menyusul di increment berikutnya — fondasi aplikasi + tab EQ lebih dulu, sesuai urutan uji.');
    }
  }

  Widget _placeholder(String msg) {
    return Center(
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: S3Colors.panel,
          border: Border.all(color: S3Colors.line),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(msg,
            style: const TextStyle(color: S3Colors.dim, fontSize: 13),
            textAlign: TextAlign.center),
      ),
    );
  }
}

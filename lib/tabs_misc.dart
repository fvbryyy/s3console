import 'package:flutter/material.dart';

import 'device_controller.dart';
import 'theme.dart';

/// Tab PRESET / PENGATURAN / INFO — mengikuti panel web & rancangan.
/// Kontrak API: POST /api/preset {name} untuk muat (pabrik: flat, speaker,
/// vokal, bass, malam; user: 'user:<i>'), POST /api/save {slot} untuk simpan.

class PresetScreen extends StatelessWidget {
  final DeviceController ctl;
  const PresetScreen({super.key, required this.ctl});

  static const _factory = [
    ('flat', 'Flat'),
    ('speaker', 'Speaker DIY'),
    ('vokal', 'Vokal'),
    ('bass', 'Bass'),
    ('malam', 'Malam'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = ctl.state!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PRESET PABRIK',
              style: TextStyle(
                  color: S3Colors.dim,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _factory)
                _bigButton(
                  context,
                  p.$2,
                  () => ctl.loadPreset(p.$1, p.$2),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const Text('PRESET USER (10 SLOT)',
              style: TextStyle(
                  color: S3Colors.dim,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          for (var i = 0; i < 10; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: s3Raised(S3Colors.panel, radius: 8),
                child: Row(
                  children: [
                    Text('Slot ${i + 1}',
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Text(i < s.slots.length && s.slots[i] != 0 ? 'Terisi' : 'Kosong',
                        style: TextStyle(
                            fontSize: 12,
                            color: i < s.slots.length && s.slots[i] != 0
                                ? S3Colors.accb
                                : S3Colors.dim)),
                    const Spacer(),
                    _smallButton(
                      'MUAT',
                      i < s.slots.length && s.slots[i] != 0
                          ? () => ctl.loadPreset('user:$i', 'User ${i + 1}')
                          : null,
                    ),
                    const SizedBox(width: 6),
                    _smallButton(
                      'SIMPAN',
                      () async {
                        final ok = await _confirm(context,
                            'Simpan ke Slot ${i + 1}?',
                            'Keadaan sekarang (reguler + DLMS) akan disimpan ke slot ini, menimpa isi lama.');
                        if (ok) await ctl.saveToSlot(i);
                      },
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
          const Text(
            'Preset yang dimuat menimpa keadaan sekarang. Keadaan juga tersimpan otomatis (SIMPAN/auto-save) terpisah dari slot-slot ini.',
            style: TextStyle(color: S3Colors.dim, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _bigButton(BuildContext context, String label, VoidCallback onTap) {
    return Material(
      color: S3Colors.card,
      elevation: 2,
      shadowColor: Colors.black,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          child: Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _smallButton(String label, VoidCallback? onTap) {
    return Material(
      color: S3Colors.card,
      elevation: 2,
      shadowColor: Colors.black,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: onTap == null ? S3Colors.dim : S3Colors.txt)),
        ),
      ),
    );
  }
}

Future<bool> _confirm(BuildContext context, String title, String body) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: S3Colors.panel,
      title: Text(title, style: const TextStyle(fontSize: 16)),
      content: Text(body,
          style: const TextStyle(color: S3Colors.dim, fontSize: 13)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal')),
        TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Ya, lanjutkan')),
      ],
    ),
  );
  return r ?? false;
}

class PengaturanScreen extends StatelessWidget {
  final DeviceController ctl;
  const PengaturanScreen({super.key, required this.ctl});

  @override
  Widget build(BuildContext context) {
    final s = ctl.state!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PENYIMPANAN',
              style: TextStyle(
                  color: S3Colors.dim,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _row(
            'Simpan otomatis',
            'Keadaan tersimpan sendiri beberapa saat setelah ada perubahan (menimpa blob yang sama di NVS — tidak memenuhi memori).',
            Switch(
              value: s.autosave,
              activeThumbColor: S3Colors.green,
              onChanged: (v) => ctl.setParam('autosave', v ? 1 : 0),
            ),
          ),
          _row(
            'Muat ulang keadaan',
            'Ambil ulang seluruh keadaan dari alat (berguna setelah mengubah lewat panel web).',
            _btn('Muat ulang', () => ctl.refreshState()),
          ),
          const SizedBox(height: 18),
          const Text('RESET',
              style: TextStyle(
                  color: S3Colors.dim,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _row(
            'Reset setelan',
            'Kembalikan semua parameter ke bawaan, tanpa menghapus kredensial WiFi.',
            _btn('Reset setelan', () async {
              final ok = await _confirm(context, 'Reset setelan?',
                  'Semua parameter reguler & DLMS kembali ke bawaan. Preset user tidak ikut terhapus.');
              if (ok) {
                ctl.sendNow({'resetSoft': '1'});
                await Future.delayed(const Duration(milliseconds: 600));
                await ctl.refreshState();
              }
            }, danger: true),
          ),
          _row(
            'Reset pabrik',
            'Hapus semua setelan & preset user. Alat akan mulai ulang; kredensial WiFi tetap disimpan.',
            _btn('Reset pabrik', () async {
              final ok = await _confirm(context, 'Reset pabrik?',
                  'Semua setelan dan preset user dihapus. Alat mulai ulang dari keadaan senyap.');
              if (ok) {
                ctl.sendNow({'resetFactory': '1'});
                await Future.delayed(const Duration(milliseconds: 800));
                ctl.disconnect();
              }
            }, danger: true),
          ),
          const SizedBox(height: 18),
          const Text('KONEKSI',
              style: TextStyle(
                  color: S3Colors.dim,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _WifiSection(ctl: ctl),
          const SizedBox(height: 8),
          _row(
            'Putuskan koneksi',
            'Kembali ke layar sambung. Alat tetap menyala dan bisa disambung lagi.',
            _btn('Putuskan', () => ctl.disconnect()),
          ),
        ],
      ),
    );
  }

  Widget _row(String title, String desc, Widget action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: s3Raised(S3Colors.panel, radius: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(desc,
                      style:
                          const TextStyle(color: S3Colors.dim, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            action,
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, VoidCallback onTap, {bool danger = false}) {
    return Material(
      color: S3Colors.card,
      elevation: 2,
      shadowColor: Colors.black,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: danger ? S3Colors.red : S3Colors.txt)),
        ),
      ),
    );
  }
}

class InfoScreen extends StatelessWidget {
  final DeviceController ctl;
  const InfoScreen({super.key, required this.ctl});

  @override
  Widget build(BuildContext context) {
    final s = ctl.state!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                    color: S3Colors.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 9),
              const Text('S3 AIR',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              const Text('USB DAC & DLMS Console',
                  style: TextStyle(color: S3Colors.accb, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          _kv('Firmware alat', s.fw.isEmpty ? '—' : s.fw),
          _kv('Jaringan', s.net.isEmpty ? '—' : s.net),
          _kv('Alamat alat', ctl.host),
          _kv('Underrun (ur)', '${s.ur}'),
          _kv('Overflow (ov)', '${s.ov}'),
          _kv('Flush NaN/Inf (flt)', '${ctl.meter.flt}'),
          const SizedBox(height: 16),
          const Text(
            'ur/ov = 0 berarti pemrosesan audio selalu selesai dalam anggaran waktu blok (10,67 ms) — tidak ada serak/patah. flt menghitung sampel rusak yang diganti senyap oleh lapisan fail-silent.',
            style: TextStyle(color: S3Colors.dim, fontSize: 12),
          ),
          const SizedBox(height: 22),
          const Text('Developed by bryyy',
              style: TextStyle(color: S3Colors.dim, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: s3Raised(S3Colors.panel, radius: 8),
        child: Row(
          children: [
            SizedBox(
                width: 170,
                child: Text(k,
                    style:
                        const TextStyle(color: S3Colors.dim, fontSize: 12.5))),
            Text(v,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}


/// Ganti jaringan WiFi alat dari aplikasi — fungsi yang dulu hanya ada di
/// panel web; wajib ada sebelum panel diturunkan jadi halaman darurat
/// (keputusan user 2026-11-13: setelan full APK + halaman darurat kecil).
class _WifiSection extends StatefulWidget {
  final DeviceController ctl;
  const _WifiSection({required this.ctl});

  @override
  State<_WifiSection> createState() => _WifiSectionState();
}

class _WifiSectionState extends State<_WifiSection> {
  final _ssid = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _ssid.dispose();
    _pass.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: S3Colors.dim, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF101216),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: S3Colors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: S3Colors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: S3Colors.cyan),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      );

  Future<void> _save() async {
    final ssid = _ssid.text.trim();
    if (ssid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi dulu nama WiFi (SSID)-nya.')),
      );
      return;
    }
    final ok = await _confirm(context, 'Ganti jaringan WiFi alat?',
        'Alat akan mulai ulang dan pindah ke "$ssid". HP ini harus tersambung ke jaringan yang sama agar bisa menyambung lagi dari aplikasi.');
    if (!ok) return;
    setState(() => _busy = true);
    final done = await widget.ctl.setWifi(ssid, _pass.text);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(done
            ? 'Tersimpan — alat mulai ulang ke "$ssid". Sambungkan HP ke jaringan itu, lalu sambung ulang.'
            : 'Gagal mengirim ke alat. Coba lagi.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: s3Raised(S3Colors.panel, radius: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Jaringan WiFi alat',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          const Text(
            'Pindahkan alat ke jaringan WiFi lain (mis. ganti router / kata sandi). Alat mulai ulang setelah disimpan.',
            style: TextStyle(color: S3Colors.dim, fontSize: 12),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _ssid,
            style: const TextStyle(fontSize: 13.5),
            decoration: _dec('Nama WiFi (SSID)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pass,
            obscureText: true,
            style: const TextStyle(fontSize: 13.5),
            decoration: _dec('Kata sandi WiFi (kosongkan bila terbuka)'),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: S3Colors.card,
              elevation: 2,
              shadowColor: Colors.black,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: _busy ? null : _save,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  child: Text(_busy ? 'Mengirim…' : 'Simpan & mulai ulang',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

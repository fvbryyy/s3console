// Tema S3 Air — token warna SATU SUMBER dari rancangan aplikasi (mockup v22).
// Jangan menyebar angka warna ke layar; semua ambil dari sini.
import 'package:flutter/material.dart';

class S3Colors {
  static const bg = Color(0xFF17191D); // latar utama
  static const strip = Color(0xFF1E2127); // badan strip fader
  static const panel = Color(0xFF1D2026); // panel/kartu gelap
  static const card = Color(0xFF2A2E36); // kartu lebih terang
  static const line = Color(0xFF383E48); // garis pemisah
  static const txt = Color(0xFFE8ECF0); // teks utama
  static const dim = Color(0xFF8A94A0); // teks redup
  static const blue = Color(0xFF346EA5); // tab aktif / tombol ON
  static const cyan = Color(0xFF38C7E0); // aksen pilihan / spektrum
  static const red = Color(0xFFF47064); // garis penanda kap master / clip
  static const muteRed = Color(0xFFC0392B); // blok MUTE aktif
  static const yellow = Color(0xFFF8CD37);
  static const green = Color(0xFF2EA05A); // status terhubung
  static const rose = Color(0xFFE58F8F);
  static const amber = Color(0xFFE8A33D); // titik "belum tersimpan"
  static const graphBg = Color(0xFF101216);
  // token tambahan persis rancangan v22 (appmock_s3air.py)
  static const plate = Color(0xFF2FBF71); // pil nama kanal di panel detail
  static const accb = Color(0xFF7EE2A8); // teks hijau muda "Terhubung"/subjudul
  static const slate = Color(0xFF54606E); // blok REGULER aktif pada saklar mode
  static const accDark = Color(0xFF08120C); // teks gelap di atas hijau
  static const meterGreen = Color(0xFF34C76E); // segmen meter bawah
  static const rtaBar = Color(0xFF2B5475); // batang spektrum gaya rancangan
  static const rtaCap = Color(0xFF40A8A0); // topi batang spektrum
  static const capRed = Color(0xFFCD3C30); // kap fader master (blok merah)
}

/// Warna 3 band PEQ DLMS pada rancangan: merah, kuning, hijau.
const dlmsBandColors = <Color>[
  Color(0xFFF26D6D),
  Color(0xFFF8CD37),
  Color(0xFF52C76E),
];

/// Frekuensi tetap 3 band PEQ DLMS (firmware): 100 Hz, 1 kHz, 8 kHz.
const dlmsBandFreqs = <double>[100, 1000, 8000];

/// Warna titik tiap band PEQ (selaras panel web).
const bandColors = <Color>[
  Color(0xFFEF6A5A), Color(0xFFF28C4B), Color(0xFFF8CD37), Color(0xFFB7D94E),
  Color(0xFF4ECB71), Color(0xFF38C7E0), Color(0xFF4B9BEF), Color(0xFF7A6FF0),
  Color(0xFFB06FE8), Color(0xFFF470B8),
];

ThemeData buildS3Theme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: S3Colors.bg,
    colorScheme: const ColorScheme.dark(
      surface: S3Colors.panel,
      primary: S3Colors.blue,
      secondary: S3Colors.cyan,
      onSurface: S3Colors.txt,
    ),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: S3Colors.txt, fontSize: 13),
      bodySmall: TextStyle(color: S3Colors.dim, fontSize: 11),
    ),
    dividerColor: S3Colors.line,
  );
}

/// Format angka gaya panel: desimal koma. Contoh: fmtDb(-4.44) -> "-4,4 dB".
String fmtNum(double v, [int dec = 1]) =>
    v.toStringAsFixed(dec).replaceAll('.', ',');
String fmtDb(double v, [int dec = 1]) => '${fmtNum(v, dec)} dB';

/// Sistem kedalaman visual ("perspektif"): permukaan yang bisa ditekan /
/// penting dibuat TERANGKAT — gradasi vertikal halus (terang di atas, gelap
/// di bawah), tepi atas lebih terang, dan bayangan lembut di bawahnya.
/// Bidang data (grafik, meter) tetap cekung gelap agar kontrasnya jelas:
/// mata langsung tahu mana tombol, mana tampilan.
LinearGradient s3Grad(Color base) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(base, Colors.white, 0.08)!,
        Color.lerp(base, Colors.black, 0.18)!,
      ],
    );

BoxDecoration s3Raised(Color base,
    {double radius = 9,
    Color? borderColor,
    double borderWidth = 1,
    List<BoxShadow>? shadows}) {
  return BoxDecoration(
    gradient: s3Grad(base),
    border: Border.all(
        color: borderColor ?? Color.lerp(base, Colors.white, 0.12)!,
        width: borderWidth),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: shadows ??
        const [
          BoxShadow(
              color: Color(0x59000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
  );
}

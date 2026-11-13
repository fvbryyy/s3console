// Strip kanal & kenop persis rancangan v22 (appmock_s3air.py):
// strip = nama + gain + rel berskala dB + kap (master blok merah, lain grafit)
// + meter segmen hijau/kuning/merah + tombol MUTE lebar di kaki.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

/// Skala fader strip rancangan: -60 .. +12 dB.
const stripDbMin = -60.0, stripDbMax = 12.0;
double dbToFrac(double db) =>
    ((db - stripDbMin) / (stripDbMax - stripDbMin)).clamp(0.0, 1.0).toDouble();
double fracToDb(double f) => stripDbMin + f * (stripDbMax - stripDbMin);

/// Pemetaan logaritmik untuk kenop (frekuensi, attack, release).
double fracOfLog(double v, double min, double max) =>
    (math.log(v / min) / math.log(max / min)).clamp(0.0, 1.0).toDouble();
double valOfLog(double f, double min, double max) =>
    min * math.pow(max / min, f).toDouble();

class DesignStrip extends StatelessWidget {
  final String name;
  final String gainText;
  final double faderDb;
  final double meterFrac; // 0..1
  final bool selected;
  final bool muted;
  final bool master;
  final VoidCallback onTap;
  final ValueChanged<double> onFaderDb; // dipanggil kontinu saat seret
  final VoidCallback onFaderEnd;
  final VoidCallback onMute;
  // penyesuaian untuk strip reguler (rentang & tombol kaki berbeda)
  final double dbMin;
  final double dbMax;
  final List<String>? scaleLabels;
  final String footLabel;
  final Color? footActiveColor;
  const DesignStrip({
    super.key,
    required this.name,
    required this.gainText,
    required this.faderDb,
    required this.meterFrac,
    required this.selected,
    required this.muted,
    required this.master,
    required this.onTap,
    required this.onFaderDb,
    required this.onFaderEnd,
    required this.onMute,
    this.dbMin = stripDbMin,
    this.dbMax = stripDbMax,
    this.scaleLabels,
    this.footLabel = 'MUTE',
    this.footActiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: S3Colors.strip,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? S3Colors.cyan : S3Colors.line,
            width: selected ? 2.5 : 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
        child: Column(
          children: [
            // Nama kanal di atas pelat berwarna agar beda & terbaca sekilas:
            // IN = biru, OUT = hijau (sama dengan pil panel detail), MASTER = merah.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: master
                    ? S3Colors.capRed
                    : (name.startsWith('IN')
                        ? S3Colors.blue
                        : S3Colors.plate),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: (!master && !name.startsWith('IN'))
                          ? S3Colors.accDark
                          : Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 4),
            Text(gainText,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFFBEF0F5))),
            const SizedBox(height: 6),
            Expanded(
              child: _StripFader(
                frac: ((faderDb - dbMin) / (dbMax - dbMin))
                    .clamp(0.0, 1.0)
                    .toDouble(),
                meterFrac: meterFrac,
                master: master,
                labels: scaleLabels,
                onFrac: (f) => onFaderDb(dbMin + f * (dbMax - dbMin)),
                onEnd: onFaderEnd,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              width: double.infinity,
              child: Material(
                color: muted
                    ? (footActiveColor ?? S3Colors.muteRed)
                    : S3Colors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                  side: muted
                      ? BorderSide.none
                      : const BorderSide(color: S3Colors.line),
                ),
                child: InkWell(
                  onTap: onMute,
                  borderRadius: BorderRadius.circular(7),
                  child: Center(
                    child: Text(footLabel,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: muted ? Colors.white : S3Colors.dim)),
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

class _StripFader extends StatelessWidget {
  final double frac;
  final double meterFrac;
  final bool master;
  final List<String>? labels;
  final ValueChanged<double> onFrac;
  final VoidCallback onEnd;
  const _StripFader({
    required this.frac,
    required this.meterFrac,
    required this.master,
    required this.labels,
    required this.onFrac,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      void fromDy(double dy) =>
          onFrac((1 - dy / c.maxHeight).clamp(0.0, 1.0).toDouble());
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (d) => fromDy(d.localPosition.dy),
        onVerticalDragUpdate: (d) => fromDy(d.localPosition.dy),
        onVerticalDragEnd: (_) => onEnd(),
        onTapDown: (d) => fromDy(d.localPosition.dy),
        onTapUp: (_) => onEnd(),
        child: CustomPaint(
          size: Size(c.maxWidth, c.maxHeight),
          painter: _StripFaderPainter(
              frac: frac, meterFrac: meterFrac, master: master, labels: labels),
        ),
      );
    });
  }
}

class _StripFaderPainter extends CustomPainter {
  final double frac;
  final double meterFrac;
  final bool master;
  final List<String>? labels;
  _StripFaderPainter(
      {required this.frac,
      required this.meterFrac,
      required this.master,
      required this.labels});

  static const _scale = ['+12', '+6', '0', '-6', '-12', '-24', '-36', '-48', '-60'];

  @override
  void paint(Canvas canvas, Size size) {
    const labelW = 26.0; // kolom angka skala di kiri rel
    final railX = labelW + 20;
    const top = 8.0, bot = 8.0;
    final railTop = top, railBot = size.height - bot;
    final railH = railBot - railTop;
    final scale = labels ?? _scale;

    // angka skala
    for (var i = 0; i < scale.length; i++) {
      final y = railTop + railH * i / (scale.length - 1);
      final tp = TextPainter(
        text: TextSpan(
            text: scale[i],
            style: const TextStyle(color: S3Colors.dim, fontSize: 8.5)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(labelW - tp.width, y - tp.height / 2));
    }
    // rel
    canvas.drawLine(
      Offset(railX, railTop),
      Offset(railX, railBot),
      Paint()
        ..color = const Color(0xFF585F6E)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    // kap
    final capY = railTop + railH * (1 - frac);
    const capW = 40.0, capH = 20.0;
    final capRect =
        Rect.fromLTWH(railX - capW / 2, capY - capH / 2, capW, capH);
    final rr = RRect.fromRectAndRadius(capRect, const Radius.circular(4));
    canvas.drawRRect(
        rr, Paint()..color = master ? S3Colors.capRed : const Color(0xFF343A42));
    canvas.drawRRect(
      rr,
      Paint()
        ..color = master ? const Color(0xFF6E231C) : const Color(0xFF969EA8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawLine(
      Offset(capRect.left + 2, capY),
      Offset(capRect.right - 2, capY),
      Paint()
        ..color = const Color(0xFFF5EBEB)
        ..strokeWidth = 2.2,
    );
    // meter segmen (20) di kanan rel
    const segs = 20;
    final mx = railX + 30;
    final segH = railH / segs;
    final lit = (meterFrac.clamp(0, 1) * segs).round();
    for (var i = 0; i < segs; i++) {
      final y = railBot - (i + 1) * segH;
      Color col;
      if (i >= lit) {
        col = const Color(0xFF282E36);
      } else if (i < 14) {
        col = S3Colors.meterGreen;
      } else if (i < 17) {
        col = S3Colors.yellow;
      } else {
        col = S3Colors.red;
      }
      canvas.drawRect(Rect.fromLTWH(mx, y + 1, 10, segH - 2), Paint()..color = col);
    }
  }

  @override
  bool shouldRepaint(_StripFaderPainter old) =>
      old.frac != frac || old.meterFrac != meterFrac || old.master != master;
}

/// Kenop putar gaya rancangan: busur berwarna 270°, jarum, label di bawah,
/// kotak nilai di bawah label. Seret vertikal untuk mengubah nilai.
class S3Knob extends StatelessWidget {
  final String label;
  final String valueText;
  final double frac; // 0..1
  final Color arcColor;
  final ValueChanged<double> onFrac;
  final VoidCallback? onEnd;
  final double diameter;
  const S3Knob({
    super.key,
    required this.label,
    required this.valueText,
    required this.frac,
    required this.arcColor,
    required this.onFrac,
    this.onEnd,
    this.diameter = 96,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (d) =>
              onFrac((frac - d.delta.dy / 160).clamp(0.0, 1.0).toDouble()),
          onVerticalDragEnd: (_) => onEnd?.call(),
          child: CustomPaint(
            size: Size(diameter, diameter),
            painter: _KnobPainter(frac: frac, arcColor: arcColor),
          ),
        ),
        const SizedBox(height: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: S3Colors.dim)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0C0E),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(valueText,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6ED0E4))),
        ),
      ],
    );
  }
}

class _KnobPainter extends CustomPainter {
  final double frac;
  final Color arcColor;
  _KnobPainter({required this.frac, required this.arcColor});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;
    // badan kenop
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF0D0F12));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFF4A525C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // busur nilai: mulai 135° (bawah-kiri), menyapu 270° searah jarum jam
    final arcRect = Rect.fromCircle(center: c, radius: r - 5);
    canvas.drawArc(
      arcRect,
      math.pi * 0.75,
      math.pi * 1.5 * frac,
      false,
      Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    // jarum: sudut dari tegak, -135°..+135°
    final th = (-135 + 270 * frac) * math.pi / 180;
    final tip = Offset(
      c.dx + (r - 11) * math.sin(th),
      c.dy - (r - 11) * math.cos(th),
    );
    canvas.drawLine(
      c,
      tip,
      Paint()
        ..color = S3Colors.txt
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_KnobPainter old) =>
      old.frac != frac || old.arcColor != arcColor;
}

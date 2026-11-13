// Tab RTA: spektrum 31 band memenuhi layar, gaya batang rancangan.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'device_controller.dart';
import 'theme.dart'; // rtaGradient + rtaColorAt

class RtaScreen extends StatelessWidget {
  final DeviceController ctl;
  const RtaScreen({super.key, required this.ctl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: S3Colors.graphBg,
          border: Border.all(color: S3Colors.line),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(
          size: Size.infinite,
          painter: _RtaPainter(rta: ctl.rta),
        ),
      ),
    );
  }
}

class _RtaPainter extends CustomPainter {
  final List<double> rta;
  _RtaPainter({required this.rta});

  static const _freqs = [
    31.0, 62.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // garis dB
    for (final db in [0.0, -12.0, -24.0, -36.0, -48.0]) {
      final y = size.height * (-db / 66);
      canvas.drawLine(Offset(30, y), Offset(size.width - 8, y),
          Paint()..color = const Color(0xFF232830)..strokeWidth = 1);
      final tp = TextPainter(
        text: TextSpan(
            text: '${db.round()}',
            style: const TextStyle(color: S3Colors.dim, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(4, y - 6));
    }
    if (rta.length >= 31) {
      final bw = (size.width - 44) / 31;
      for (var i = 0; i < 31; i++) {
        final frac = ((rta[i] + 60) / 60).clamp(0.0, 1.0).toDouble();
        final h = frac * (size.height - 30);
        final x = 36 + i * bw;
        final y = size.height - 24 - h;
        canvas.drawRect(
            Rect.fromLTWH(x, y, bw - 2, h),
            Paint()
              ..shader = rtaGradient(
                  Rect.fromLTWH(36, 6, size.width - 44, size.height - 30)));
        canvas.drawRect(Rect.fromLTWH(x, y, bw - 2, 6),
            Paint()..color = rtaColorAt(frac));
      }
    }
    // label frekuensi (log)
    for (final f in _freqs) {
      final x = 36 +
          (size.width - 44) *
              (math.log(f / 20) / math.log(20000 / 20));
      final tp = TextPainter(
        text: TextSpan(
            text: f >= 1000 ? '${(f / 1000).round()}k' : '${f.round()}',
            style: const TextStyle(color: S3Colors.dim, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - 16));
    }
  }

  @override
  bool shouldRepaint(_RtaPainter old) => true;
}

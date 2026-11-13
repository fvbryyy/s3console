// Widget fader vertikal gaya konsol: rel slot gelap + kap mixer bergerigi
// dengan garis penanda berwarna; nilai diseret kontinu (bukan saat lepas).
import 'package:flutter/material.dart';
import 'theme.dart';

class VerticalFader extends StatelessWidget {
  final double value; // sudah dinormalisasi 0..1 oleh pemanggil
  final ValueChanged<double> onChanged;
  final VoidCallback? onChangeEnd;
  final Color marker;
  final double height;
  const VerticalFader({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.marker = S3Colors.txt,
    this.height = 150,
  });

  void _fromDy(double dy, double h) {
    final v = 1 - (dy / h).clamp(0.0, 1.0);
    onChanged(v.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: height,
      child: LayoutBuilder(builder: (context, c) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (d) => _fromDy(d.localPosition.dy, c.maxHeight),
          onVerticalDragUpdate: (d) => _fromDy(d.localPosition.dy, c.maxHeight),
          onVerticalDragEnd: (_) => onChangeEnd?.call(),
          onTapDown: (d) => _fromDy(d.localPosition.dy, c.maxHeight),
          onTapUp: (_) => onChangeEnd?.call(),
          child: CustomPaint(
            size: Size(44, c.maxHeight),
            painter: _FaderPainter(value: value, marker: marker),
          ),
        );
      }),
    );
  }
}

class _FaderPainter extends CustomPainter {
  final double value;
  final Color marker;
  _FaderPainter({required this.value, required this.marker});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const padTop = 12.0, padBot = 12.0;
    final railTop = padTop, railBot = size.height - padBot;
    final railH = railBot - railTop;

    // garis skala
    final tick = Paint()
      ..color = S3Colors.line
      ..strokeWidth = 1;
    for (var i = 0; i <= 10; i++) {
      final y = railTop + railH * i / 10;
      final len = i == 5 ? 9.0 : 5.0;
      canvas.drawLine(Offset(cx - 15 - len, y), Offset(cx - 15, y), tick);
      canvas.drawLine(Offset(cx + 15, y), Offset(cx + 15 + len, y), tick);
    }
    // slot rel
    final slot = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 2.5, railTop, 5, railH),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(slot, Paint()..color = const Color(0xFF0B0C0E));
    // penanda tengah (detent 0 dB)
    canvas.drawLine(
      Offset(cx - 13, railTop + railH / 2),
      Offset(cx + 13, railTop + railH / 2),
      Paint()
        ..color = S3Colors.dim.withValues(alpha: 0.55)
        ..strokeWidth = 1,
    );
    // kap mixer
    final capY = railTop + railH * (1 - value);
    const capW = 34.0, capH = 20.0;
    final capRect = Rect.fromLTWH(cx - capW / 2, capY - capH / 2, capW, capH);
    final cap = RRect.fromRectAndRadius(capRect, const Radius.circular(3));
    canvas.drawRRect(cap, Paint()..color = const Color(0xFF33373F));
    canvas.drawRRect(
      cap,
      Paint()
        ..color = S3Colors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    // gerigi kap
    final grip = Paint()
      ..color = const Color(0xFF1C1F24)
      ..strokeWidth = 1.4;
    for (var i = -1; i <= 1; i++) {
      if (i == 0) continue;
      final y = capY + i * 4.5;
      canvas.drawLine(Offset(cx - 11, y), Offset(cx + 11, y), grip);
    }
    // garis penanda nilai
    canvas.drawLine(
      Offset(cx - 13, capY),
      Offset(cx + 13, capY),
      Paint()
        ..color = marker
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(_FaderPainter old) =>
      old.value != value || old.marker != marker;
}

/// Meter batang vertikal satu kanal (nilai linear 0..1).
class LevelBar extends StatelessWidget {
  final double level;
  final double height;
  const LevelBar({super.key, required this.level, this.height = 150});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(7, height),
      painter: _BarPainter(level.clamp(0, 1).toDouble()),
    );
  }
}

class _BarPainter extends CustomPainter {
  final double level;
  _BarPainter(this.level);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0B0C0E),
    );
    const segs = 18;
    final segH = size.height / segs;
    final lit = (level * segs).round();
    for (var i = 0; i < lit; i++) {
      final fromTop = segs - 1 - i;
      final y = fromTop * segH;
      Color c;
      if (fromTop < 3) {
        c = S3Colors.red;
      } else if (fromTop < 6) {
        c = S3Colors.yellow;
      } else {
        c = S3Colors.cyan;
      }
      canvas.drawRect(Rect.fromLTWH(0.5, y + 0.7, size.width - 1, segH - 1.4),
          Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.level != level;
}

/// Tombol blok di kaki strip: MUTE (aktif = merah) atau ON (aktif = biru).
class StripFootButton extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  const StripFootButton({
    super.key,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? activeColor : S3Colors.card,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 7),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: active ? Colors.white : S3Colors.dim,
            ),
          ),
        ),
      ),
    );
  }
}

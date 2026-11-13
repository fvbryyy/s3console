// Tab EQ (mode reguler): grafik PEQ + spektrum RTA, chip band, kotak editor,
// dan bank fader 10 band + master — meniru panel web & rancangan aplikasi.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'device_controller.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets_fader.dart';

const _fMin = 20.0, _fMax = 20000.0, _dbRange = 18.0;

double _xToF(double x, double w) =>
    _fMin * math.pow(_fMax / _fMin, x / w).toDouble();
double _fToX(double f, double w) =>
    w * (math.log(f / _fMin) / math.log(_fMax / _fMin));

/// Magnitudo biquad RBJ (dB) untuk satu band pada frekuensi f.
double _bandDb(BandState b, double f) {
  const fs = 48000.0;
  if (b.g == 0 && b.t == 0) return 0;
  final a = math.pow(10, b.g / 40).toDouble();
  final w0 = 2 * math.pi * b.f / fs;
  final alpha = math.sin(w0) / (2 * b.q);
  final cw = math.cos(w0);
  final sq = 2 * math.sqrt(a) * alpha;
  double b0, b1, b2, a0, a1, a2;
  switch (b.t) {
    case 1: // low shelf
      b0 = a * ((a + 1) - (a - 1) * cw + sq);
      b1 = 2 * a * ((a - 1) - (a + 1) * cw);
      b2 = a * ((a + 1) - (a - 1) * cw - sq);
      a0 = (a + 1) + (a - 1) * cw + sq;
      a1 = -2 * ((a - 1) + (a + 1) * cw);
      a2 = (a + 1) + (a - 1) * cw - sq;
      break;
    case 2: // high shelf
      b0 = a * ((a + 1) + (a - 1) * cw + sq);
      b1 = -2 * a * ((a - 1) + (a + 1) * cw);
      b2 = a * ((a + 1) + (a - 1) * cw - sq);
      a0 = (a + 1) - (a - 1) * cw + sq;
      a1 = 2 * ((a - 1) - (a + 1) * cw);
      a2 = (a + 1) - (a - 1) * cw - sq;
      break;
    default: // peaking
      b0 = 1 + alpha * a;
      b1 = -2 * cw;
      b2 = 1 - alpha * a;
      a0 = 1 + alpha / a;
      a1 = -2 * cw;
      a2 = 1 - alpha / a;
  }
  final w = 2 * math.pi * f / fs;
  final c1 = math.cos(w), c2 = math.cos(2 * w);
  final num = b0 * b0 + b1 * b1 + b2 * b2 + 2 * (b0 * b1 + b1 * b2) * c1 + 2 * b0 * b2 * c2;
  final den = a0 * a0 + a1 * a1 + a2 * a2 + 2 * (a0 * a1 + a1 * a2) * c1 + 2 * a0 * a2 * c2;
  if (num <= 0 || den <= 0) return 0;
  return 10 * math.log(num / den) / math.ln10;
}

class EqScreen extends StatelessWidget {
  final DeviceController ctl;
  final VoidCallback onOpenDlms;
  const EqScreen({super.key, required this.ctl, required this.onOpenDlms});

  @override
  Widget build(BuildContext context) {
    final s = ctl.state;
    if (s == null) return const SizedBox.shrink();
    if (s.dlms.on) {
      // Persis rancangan layar 3: pemberitahuan bypass di kartu tengah.
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 560,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
              decoration: BoxDecoration(
                color: S3Colors.panel,
                border: Border.all(color: S3Colors.line),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('EQ REGULER SEDANG TER-BYPASS',
                      style: TextStyle(
                          fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text(
                    'Mode DLMS aktif — rantai EQ, Gate, dan Compressor reguler tidak dipakai.\nPEQ tersedia per output di tab CHANNEL.',
                    style: TextStyle(color: S3Colors.dim, fontSize: 13.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: S3Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 34, vertical: 13),
                    ),
                    onPressed: onOpenDlms,
                    child: const Text('BUKA PEQ DLMS',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Atau matikan DLMS lewat saklar di kanan atas untuk memakai EQ 10 band.',
              style: TextStyle(color: S3Colors.dim, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: _Graph(ctl: ctl),
        ),
        _EditorRow(ctl: ctl),
        _Bank(ctl: ctl),
      ],
    );
  }
}

class _Graph extends StatelessWidget {
  final DeviceController ctl;
  const _Graph({required this.ctl});

  @override
  Widget build(BuildContext context) {
    final s = ctl.state!;
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      int? dragBand;
      Offset toFreqGain(Offset p) => p;
      return GestureDetector(
        onPanStart: (d) {
          final p = d.localPosition;
          var best = -1;
          var bestDist = 1e9;
          for (var i = 0; i < s.bands.length; i++) {
            final b = s.bands[i];
            final bp = Offset(
              _fToX(b.f, size.width),
              size.height / 2 - (b.g / _dbRange) * (size.height / 2),
            );
            final dist = (bp - p).distance;
            if (dist < bestDist) {
              bestDist = dist;
              best = i;
            }
          }
          if (best >= 0) {
            dragBand = best;
            ctl.selectedBand = best;
            ctl.touch();
          }
        },
        onPanUpdate: (d) {
          final i = dragBand ?? ctl.selectedBand;
          final p = toFreqGain(d.localPosition);
          final f = _xToF(p.dx.clamp(0, size.width).toDouble(), size.width);
          final g = ((size.height / 2 - p.dy) / (size.height / 2) * _dbRange)
              .clamp(-15, 15)
              .toDouble();
          ctl.setBandFreqGain(i, f, g, drag: true);
        },
        onPanEnd: (_) {
          final i = dragBand ?? ctl.selectedBand;
          final b = s.bands[i];
          ctl.setBandFreqGain(i, b.f, b.g);
          dragBand = null;
        },
        child: CustomPaint(
          size: size,
          painter: _GraphPainter(
            bands: s.bands,
            rta: ctl.rta,
            selected: ctl.selectedBand,
            bypass: s.bypass,
          ),
        ),
      );
    });
  }
}

class _GraphPainter extends CustomPainter {
  final List<BandState> bands;
  final List<double> rta;
  final int selected;
  final bool bypass;
  _GraphPainter({
    required this.bands,
    required this.rta,
    required this.selected,
    required this.bypass,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = S3Colors.graphBg);
    final midY = size.height / 2;
    double dbToY(double db) => midY - (db / _dbRange) * midY;

    // grid horizontal
    final grid = Paint()
      ..color = const Color(0xFF232830)
      ..strokeWidth = 1;
    for (final db in [12.0, 6.0, -6.0, -12.0]) {
      canvas.drawLine(Offset(0, dbToY(db)), Offset(size.width, dbToY(db)), grid);
    }
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY),
        Paint()..color = const Color(0xFF2C3542)..strokeWidth = 1);
    // grid frekuensi + label
    for (final f in [31.0, 62.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0]) {
      final x = _fToX(f, size.width);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      _label(canvas, f >= 1000 ? '${(f / 1000).round()}k' : '${f.round()}',
          Offset(x + 3, size.height - 14));
    }
    for (final db in [12.0, 6.0, -6.0, -12.0]) {
      _label(canvas, db > 0 ? '+${db.round()}' : '${db.round()}',
          Offset(4, dbToY(db) - 12));
    }

    // spektrum RTA (31 band) di belakang kurva
    if (rta.length >= 31) {
      final bw = size.width / 31;
      final barPaint = Paint()..color = S3Colors.cyan.withValues(alpha: 0.33);
      for (var i = 0; i < 31; i++) {
        final frac = ((rta[i] + 60) / 60).clamp(0.0, 1.0).toDouble();
        final h = frac * size.height;
        canvas.drawRect(
          Rect.fromLTWH(i * bw + 0.5, size.height - h, bw - 1, h),
          barPaint,
        );
      }
    }

    // Kurva gabungan — sama seperti panel web: TANPA preamp (preamp bukan
    // bagian kurva; dulu kutambah dan garisnya melayang +5 dB di atas titik),
    // dan rata 0 bila bypass. Isi tembus di bawah kurva seperti panel.
    double totalAt(double f) {
      if (bypass) return 0;
      var db = 0.0;
      for (final b in bands) {
        if (b.on) db += _bandDb(b, f);
      }
      return db;
    }

    final path = Path();
    const steps = 140;
    for (var i = 0; i <= steps; i++) {
      final x = size.width * i / steps;
      final f = _xToF(x, size.width);
      final y = dbToY(totalAt(f).clamp(-_dbRange, _dbRange).toDouble());
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        fill, Paint()..color = S3Colors.cyan.withValues(alpha: 0.10));
    canvas.drawPath(
      path,
      Paint()
        ..color = S3Colors.cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    // kurva band terpilih saja (warna band-nya, seperti panel web)
    if (!bypass && selected >= 0 && selected < bands.length) {
      final b = bands[selected];
      if (b.on) {
        final bp = Path();
        for (var i = 0; i <= steps; i++) {
          final x = size.width * i / steps;
          final f = _xToF(x, size.width);
          final y = dbToY(
              _bandDb(b, f).clamp(-_dbRange, _dbRange).toDouble());
          i == 0 ? bp.moveTo(x, y) : bp.lineTo(x, y);
        }
        canvas.drawPath(
          bp,
          Paint()
            ..color = bandColors[selected % bandColors.length]
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }

    // titik band
    for (var i = 0; i < bands.length; i++) {
      final b = bands[i];
      final p = Offset(_fToX(b.f, size.width), dbToY(b.g));
      final col = bandColors[i % bandColors.length];
      final r = i == selected ? 12.5 : 10.5;
      if (i == selected) {
        canvas.drawCircle(p, 17, Paint()..color = col.withValues(alpha: 0.3));
      }
      canvas.drawCircle(
        p,
        r,
        Paint()..color = b.on ? col : S3Colors.dim,
      );
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..color = i == selected ? Colors.white : S3Colors.line
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == selected ? 2.5 : 1.2,
      );
      _label(canvas, '${i + 1}', p + const Offset(-3, -6), bold: true);
    }
  }

  void _label(Canvas canvas, String text, Offset at, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: bold ? Colors.white : S3Colors.dim,
          fontSize: 9,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_GraphPainter old) => true;
}

class _EditorRow extends StatelessWidget {
  final DeviceController ctl;
  const _EditorRow({required this.ctl});

  @override
  Widget build(BuildContext context) {
    final s = ctl.state!;
    final sel = ctl.selectedBand.clamp(0, s.bands.length - 1);
    final b = s.bands[sel];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: S3Colors.panel,
        border: Border(top: BorderSide(color: S3Colors.line)),
      ),
      child: Row(
        children: [
          // Penanda band yang sedang diedit (pemilihan band cukup dari strip
          // di bawah / titik di grafik — chip B1..B10 dulu dobel, dicabut).
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bandColors[sel % bandColors.length].withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('B${sel + 1}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          _Stepper(
            label: 'GAIN',
            value: fmtDb(b.g),
            onMinus: () => ctl.setBandField(sel, 'g', (b.g - 0.5).toString()),
            onPlus: () => ctl.setBandField(sel, 'g', (b.g + 0.5).toString()),
          ),
          _Stepper(
            label: 'FREKUENSI',
            value: b.f >= 1000
                ? '${fmtNum(b.f / 1000, 2)} kHz'
                : '${b.f.round()} Hz',
            onMinus: () =>
                ctl.setBandField(sel, 'f', (b.f / 1.0595).toString()),
            onPlus: () =>
                ctl.setBandField(sel, 'f', (b.f * 1.0595).toString()),
          ),
          _Stepper(
            label: 'Q',
            value: fmtNum(b.q, 2),
            onMinus: () => ctl.setBandField(sel, 'q', (b.q / 1.25).toString()),
            onPlus: () => ctl.setBandField(sel, 'q', (b.q * 1.25).toString()),
          ),
          const SizedBox(width: 8),
          _MiniToggle(
            label: const ['Puncak', 'Low Shelf', 'High Shelf'][b.t.clamp(0, 2)],
            onTap: () =>
                ctl.setBandField(sel, 't', ((b.t + 1) % 3).toString()),
          ),
          // ON/OFF band cukup dari tombol ON di strip band (dulu dobel di sini).
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label, value;
  final VoidCallback onMinus, onPlus;
  const _Stepper({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: S3Colors.dim, fontSize: 9)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepBtn(icon: Icons.remove, onTap: onMinus),
              Container(
                constraints: const BoxConstraints(minWidth: 62),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: Alignment.center,
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              _StepBtn(icon: Icons.add, onTap: onPlus),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: S3Colors.card,
      elevation: 2,
      shadowColor: Colors.black,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 15, color: S3Colors.txt),
        ),
      ),
    );
  }
}

class _MiniToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _MiniToggle({required this.label, this.active = false, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? S3Colors.blue : S3Colors.card,
      elevation: active ? 5 : 2,
      shadowColor: active ? S3Colors.blue : Colors.black,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: active ? Colors.white : S3Colors.dim,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _Bank extends StatelessWidget {
  final DeviceController ctl;
  const _Bank({required this.ctl});

  @override
  Widget build(BuildContext context) {
    final s = ctl.state!;
    return Container(
      height: 218,
      decoration: const BoxDecoration(
        color: S3Colors.panel,
        border: Border(top: BorderSide(color: S3Colors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: s.bands.length,
              itemBuilder: (context, i) {
                final b = s.bands[i];
                final selected = i == ctl.selectedBand;
                return GestureDetector(
                  onTap: () {
                    ctl.selectedBand = i;
                    ctl.touch();
                  },
                  child: Container(
                    width: 74,
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                    decoration: s3Raised(
                      S3Colors.strip,
                      radius: 6,
                      borderColor: selected ? S3Colors.cyan : null,
                      borderWidth: selected ? 2 : 1,
                      shadows: selected
                          ? const [
                              BoxShadow(
                                  color: Color(0x5938C7E0),
                                  blurRadius: 12,
                                  offset: Offset(0, 3)),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text('B${i + 1}',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(
                          b.f >= 1000
                              ? '${fmtNum(b.f / 1000, b.f >= 10000 ? 0 : 1)}k'
                              : '${b.f.round()}',
                          style: const TextStyle(
                              color: S3Colors.dim, fontSize: 10),
                        ),
                        Text(fmtDb(b.g),
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: VerticalFader(
                            value: (b.g + 15) / 30,
                            marker: bandColors[i % bandColors.length],
                            height: 96,
                            onChanged: (v) =>
                                ctl.setBandGain(i, v * 30 - 15, drag: true),
                            onChangeEnd: () =>
                                ctl.setBandGain(i, s.bands[i].g),
                          ),
                        ),
                        StripFootButton(
                          label: 'ON',
                          active: b.on,
                          activeColor: S3Colors.blue,
                          onTap: () =>
                              ctl.setBandField(i, 'on', b.on ? '0' : '1'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // strip master — selalu menempel di kanan
          Container(
            width: 108,
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
            decoration: BoxDecoration(
              color: S3Colors.strip,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: S3Colors.muteRed, width: 1.5),
            ),
            child: Column(
              children: [
                const Text('MAIN',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const Text('Master',
                    style: TextStyle(color: S3Colors.dim, fontSize: 10)),
                Text(fmtDb(ctl.volDb),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: LevelBar(level: ctl.meter.l, height: 96),
                      ),
                      VerticalFader(
                        value: (ctl.volDb + 60) / 60,
                        marker: S3Colors.red,
                        height: 96,
                        onChanged: (v) =>
                            ctl.setVolDb(v * 60 - 60, drag: true),
                        onChangeEnd: () => ctl.setVolDb(ctl.volDb),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: LevelBar(level: ctl.meter.r, height: 96),
                      ),
                    ],
                  ),
                ),
                StripFootButton(
                  label: 'MUTE',
                  active: s.mute,
                  activeColor: S3Colors.muteRed,
                  onTap: () => ctl.setMute(!s.mute),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

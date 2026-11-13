// Tab CHANNEL mode DLMS — persis rancangan layar 1 (v22):
// strip IN A / IN B / OUT 1 / OUT 2 / MASTER + panel detail ber-chip fungsi.
// Fungsi PEQ hidup penuh; Routing/Crossover/Delay/Limiter/Fase menyusul.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'device_controller.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets_strip.dart';

class ChannelScreen extends StatefulWidget {
  final DeviceController ctl;
  const ChannelScreen({super.key, required this.ctl});
  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  int sel = 2; // 0 IN A, 1 IN B, 2 OUT 1, 3 OUT 2, 4 MASTER
  String chip = 'PEQ';
  int peqBand = 0;

  static const _chips = ['Routing', 'Crossover', 'PEQ', 'Delay', 'Limiter', 'Fase'];
  static const _names = ['IN A', 'IN B', 'OUT 1', 'OUT 2', 'MASTER'];

  @override
  Widget build(BuildContext context) {
    final ctl = widget.ctl;
    final s = ctl.state!;
    if (!s.dlms.on) {
      return Center(
        child: Container(
          width: 470,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: S3Colors.panel,
            border: Border.all(color: S3Colors.line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Layar CHANNEL reguler (Noise Gate & Compressor) menyusul increment berikutnya. Sementara tab EQ reguler dan panel web tetap bisa dipakai.',
            style: TextStyle(color: S3Colors.dim, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final d = s.dlms;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 196,
            child: DesignStrip(
              name: 'IN A',
              gainText: fmtDb(d.inGainA),
              faderDb: d.inGainA,
              meterFrac: ctl.meter.l,
              selected: sel == 0,
              muted: !d.inOnA,
              master: false,
              onTap: () => setState(() => sel = 0),
              onFaderDb: (db) => ctl.setInGain(true, db, drag: true),
              onFaderEnd: () => ctl.setInGain(true, d.inGainA),
              onMute: () => ctl.setInOn(true, !d.inOnA),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 196,
            child: DesignStrip(
              name: 'IN B',
              gainText: fmtDb(d.inGainB),
              faderDb: d.inGainB,
              meterFrac: ctl.meter.r,
              selected: sel == 1,
              muted: !d.inOnB,
              master: false,
              onTap: () => setState(() => sel = 1),
              onFaderDb: (db) => ctl.setInGain(false, db, drag: true),
              onFaderEnd: () => ctl.setInGain(false, d.inGainB),
              onMute: () => ctl.setInOn(false, !d.inOnB),
            ),
          ),
          const SizedBox(width: 6),
          for (var ch = 0; ch < 2; ch++) ...[
            Expanded(
              flex: 196,
              child: DesignStrip(
                name: 'OUT ${ch + 1}',
                gainText: fmtDb(d.ch[ch].gain),
                faderDb: d.ch[ch].gain,
                meterFrac: ch == 0 ? ctl.meter.l : ctl.meter.r,
                selected: sel == 2 + ch,
                muted: !d.ch[ch].on,
                master: false,
                onTap: () => setState(() => sel = 2 + ch),
                onFaderDb: (db) => ctl.setChGain(ch, db, drag: true),
                onFaderEnd: () => ctl.setChGain(ch, d.ch[ch].gain),
                onMute: () => ctl.setChOn(ch, !d.ch[ch].on),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            flex: 150,
            child: DesignStrip(
              name: 'MASTER',
              gainText: fmtDb(ctl.volDb),
              faderDb: ctl.volDb,
              meterFrac: math.max(ctl.meter.l, ctl.meter.r),
              selected: sel == 4,
              muted: s.mute,
              master: true,
              onTap: () => setState(() => sel = 4),
              onFaderDb: (db) => ctl.setVolDb(db.clamp(-60, 0).toDouble(), drag: true),
              onFaderEnd: () => ctl.setVolDb(ctl.volDb),
              onMute: () => ctl.setMute(!s.mute),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 746,
            child: _detail(ctl, s),
          ),
        ],
      ),
    );
  }

  Widget _detail(DeviceController ctl, DspState s) {
    final d = s.dlms;
    return Container(
      decoration: BoxDecoration(
        color: S3Colors.panel,
        border: Border.all(color: S3Colors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: S3Colors.plate,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(_names[sel],
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: S3Colors.accDark)),
              ),
              const SizedBox(width: 10),
              if (sel == 2 || sel == 3)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final c in _chips)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _chipBtn(c, chip == c,
                                () => setState(() => chip = c)),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: _detailBody(ctl, s, d)),
        ],
      ),
    );
  }

  Widget _chipBtn(String label, bool active, VoidCallback onTap) {
    return Material(
      color: active ? S3Colors.blue : S3Colors.card,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : S3Colors.dim)),
        ),
      ),
    );
  }

  Widget _detailBody(DeviceController ctl, DspState s, DlmsState d) {
    if (sel == 0 || sel == 1) {
      final isA = sel == 0;
      final gain = isA ? d.inGainA : d.inGainB;
      final dly = isA ? d.inDlyA : d.inDlyB;
      final on = isA ? d.inOnA : d.inOnB;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PARAMETER',
              style: TextStyle(
                  color: S3Colors.dim, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              S3Knob(
                label: 'GAIN',
                valueText: fmtDb(gain),
                frac: dbToFrac(gain),
                arcColor: const Color(0xFFFAAC58),
                onFrac: (f) => ctl.setInGain(isA, fracToDb(f), drag: true),
                onEnd: () => ctl.setInGain(isA, gain),
              ),
              const SizedBox(width: 34),
              S3Knob(
                label: 'DELAY',
                valueText: '${fmtNum(dly, 1)} ms',
                frac: (dly / 100).clamp(0, 1).toDouble(),
                arcColor: const Color(0xFF6ED0E4),
                onFrac: (f) => ctl.setInDelay(isA, f * 100, drag: true),
                onEnd: () => ctl.setInDelay(isA, dly),
              ),
              const SizedBox(width: 34),
              _chipBtn(on ? 'AKTIF' : 'NONAKTIF', on,
                  () => ctl.setInOn(isA, !on)),
            ],
          ),
        ],
      );
    }
    if (sel == 4) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PARAMETER',
              style: TextStyle(
                  color: S3Colors.dim, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              S3Knob(
                label: 'VOLUME',
                valueText: fmtDb(ctl.volDb),
                frac: (ctl.volDb + 60) / 60,
                arcColor: S3Colors.red,
                onFrac: (f) => ctl.setVolDb(f * 60 - 60, drag: true),
                onEnd: () => ctl.setVolDb(ctl.volDb),
              ),
              const SizedBox(width: 34),
              _chipBtn(s.mute ? 'MUTE AKTIF' : 'MUTE', s.mute,
                  () => ctl.setMute(!s.mute)),
              const SizedBox(width: 10),
              _chipBtn(s.dim ? 'DIM AKTIF' : 'DIM', s.dim,
                  () => ctl.setDim(!s.dim)),
            ],
          ),
        ],
      );
    }
    // OUT 1 / OUT 2
    final ch = sel - 2;
    final c = d.ch[ch];
    if (chip != 'PEQ') {
      return Center(
        child: Text(
          'Panel $chip untuk ${_names[sel]} menyusul increment berikutnya.\nNilai sekarang bisa diatur dari panel web (mbahdac.local).',
          style: const TextStyle(color: S3Colors.dim, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }
    return _PeqPanel(
      ctl: ctl,
      ch: ch,
      chState: c,
      band: peqBand,
      onBand: (b) => setState(() => peqBand = b),
    );
  }
}

class _PeqPanel extends StatelessWidget {
  final DeviceController ctl;
  final int ch;
  final DlmsChState chState;
  final int band;
  final ValueChanged<int> onBand;
  const _PeqPanel({
    required this.ctl,
    required this.ch,
    required this.chState,
    required this.band,
    required this.onBand,
  });

  @override
  Widget build(BuildContext context) {
    final gains = chState.peq;
    final g = gains[band];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('PEQ 3 BAND',
                style: TextStyle(
                    color: S3Colors.dim,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            _peqToggle(),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(builder: (context, cons) {
            final size = Size(cons.maxWidth, cons.maxHeight);
            return GestureDetector(
              onPanUpdate: (dd) {
                // seret vertikal pada titik band = ubah gain band terdekat (x)
                var best = 0;
                var bestDist = 1e9;
                for (var i = 0; i < 3; i++) {
                  final x = _fToX(dlmsBandFreqs[i], size.width);
                  final dist = (x - dd.localPosition.dx).abs();
                  if (dist < bestDist) {
                    bestDist = dist.toDouble();
                    best = i;
                  }
                }
                onBand(best);
                final db = ((size.height / 2 - dd.localPosition.dy) /
                        (size.height / 2) *
                        15)
                    .clamp(-15, 15)
                    .toDouble();
                ctl.setChPeqGain(ch, best, db, drag: true);
              },
              onPanEnd: (_) =>
                  ctl.setChPeqGain(ch, band, gains[band]),
              child: CustomPaint(
                size: size,
                painter: _DlmsGraphPainter(
                  gains: gains,
                  rta: ctl.rta,
                  selected: band,
                  peqOn: chState.peqOn,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onBand(i),
                  child: Container(
                    width: 42,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: dlmsBandColors[i],
                      borderRadius: BorderRadius.circular(6),
                      border: i == band
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                    ),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: S3Colors.accDark)),
                  ),
                ),
              ),
            const SizedBox(width: 14),
            const Text('Tipe',
                style: TextStyle(color: S3Colors.dim, fontSize: 13)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: S3Colors.card,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Peak',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 14),
            Text(
              'FREQ ${_freqLabel(dlmsBandFreqs[band])} · Q 1,00 · GAIN ${fmtDb(g)}',
              style: const TextStyle(
                  color: Color(0xFF6ED0E4),
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Tanpa kenop (koreksi user): gain diatur dengan menyeret titik di
        // grafik; baris ini cukup petunjuk + tombol reset band.
        Row(
          children: [
            const Text('Seret titik di grafik untuk mengubah gain',
                style: TextStyle(color: S3Colors.dim, fontSize: 12)),
            const Spacer(),
            Material(
              color: S3Colors.card,
              borderRadius: BorderRadius.circular(7),
              child: InkWell(
                onTap: () => ctl.setChPeqGain(ch, band, 0),
                borderRadius: BorderRadius.circular(7),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Text('Reset band ${band + 1}',
                      style: const TextStyle(color: S3Colors.dim, fontSize: 12.5)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _peqToggle() {
    return Material(
      color: chState.peqOn ? S3Colors.blue : S3Colors.card,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => ctl.setChField(ch, 'peqOn', chState.peqOn ? '0' : '1'),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          child: Text(chState.peqOn ? 'PEQ ON' : 'PEQ OFF',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: chState.peqOn ? Colors.white : S3Colors.dim)),
        ),
      ),
    );
  }

  static String _freqLabel(double f) =>
      f >= 1000 ? '${fmtNum(f / 1000, f >= 10000 ? 0 : 1)} kHz' : '${f.round()} Hz';
}

double _fToX(double f, double w) =>
    w * (math.log(f / 20) / math.log(20000 / 20));
double _xToF(double x, double w) =>
    20 * math.pow(1000, x / w).toDouble();

double _peakingDb(double f0, double g, double q, double f) {
  if (g == 0) return 0;
  const fs = 48000.0;
  final a = math.pow(10, g / 40).toDouble();
  final w0 = 2 * math.pi * f0 / fs;
  final alpha = math.sin(w0) / (2 * q);
  final cw = math.cos(w0);
  final b0 = 1 + alpha * a, b1 = -2 * cw, b2 = 1 - alpha * a;
  final a0 = 1 + alpha / a, a1 = -2 * cw, a2 = 1 - alpha / a;
  final w = 2 * math.pi * f / fs;
  final c1 = math.cos(w), c2 = math.cos(2 * w);
  final num = b0 * b0 + b1 * b1 + b2 * b2 + 2 * (b0 * b1 + b1 * b2) * c1 + 2 * b0 * b2 * c2;
  final den = a0 * a0 + a1 * a1 + a2 * a2 + 2 * (a0 * a1 + a1 * a2) * c1 + 2 * a0 * a2 * c2;
  if (num <= 0 || den <= 0) return 0;
  return 10 * math.log(num / den) / math.ln10;
}

class _DlmsGraphPainter extends CustomPainter {
  final List<double> gains;
  final List<double> rta;
  final int selected;
  final bool peqOn;
  _DlmsGraphPainter({
    required this.gains,
    required this.rta,
    required this.selected,
    required this.peqOn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(7)),
      Paint()..color = const Color(0xFF0F1114),
    );
    final midY = size.height / 2;
    double dbToY(double db) => midY - (db / 15) * (midY - 16);
    // label + garis dB
    for (final db in [12.0, 6.0, 0.0, -6.0, -12.0]) {
      final y = dbToY(db);
      canvas.drawLine(
        Offset(34, y),
        Offset(size.width - 6, y),
        Paint()
          ..color = db == 0 ? const Color(0xFF465260) : const Color(0xFF212832)
          ..strokeWidth = 1,
      );
      final tp = TextPainter(
        text: TextSpan(
            text: db > 0 ? '${db.round()}' : '${db.round()}',
            style: const TextStyle(color: S3Colors.dim, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(6, y - 6));
    }
    // spektrum gaya rancangan: batang biru + topi teal
    if (rta.length >= 31) {
      final bw = (size.width - 40) / 31;
      for (var i = 0; i < 31; i++) {
        final frac = ((rta[i] + 60) / 54).clamp(0.0, 1.0).toDouble();
        final h = frac * (size.height - 44);
        final x = 36 + i * bw;
        final y = size.height - 26 - h;
        canvas.drawRect(Rect.fromLTWH(x, y, bw - 2, h), Paint()..color = S3Colors.rtaBar);
        canvas.drawRect(Rect.fromLTWH(x, y, bw - 2, 5), Paint()..color = S3Colors.rtaCap);
      }
    }
    // label frekuensi
    for (final f in [20.0, 50.0, 100.0, 200.0, 500.0, 1000.0, 2000.0, 5000.0, 10000.0, 20000.0]) {
      final x = _fToX(f, size.width);
      final tp = TextPainter(
        text: TextSpan(
            text: f >= 1000 ? '${(f / 1000).round()}k' : '${f.round()}',
            style: const TextStyle(color: S3Colors.dim, fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x, size.height - 14));
    }
    if (peqOn) {
      // kurva gabungan putih
      final path = Path();
      const steps = 120;
      for (var i = 0; i <= steps; i++) {
        final x = size.width * i / steps;
        final f = _xToF(x, size.width);
        var db = 0.0;
        for (var b = 0; b < 3; b++) {
          db += _peakingDb(dlmsBandFreqs[b], gains[b], 1.0, f);
        }
        final y = dbToY(db.clamp(-15, 15).toDouble());
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFF0F4F8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
      // titik band
      for (var i = 0; i < 3; i++) {
        final p = Offset(_fToX(dlmsBandFreqs[i], size.width), dbToY(gains[i]));
        final col = dlmsBandColors[i];
        canvas.drawCircle(p, 12, Paint()..color = col);
        canvas.drawCircle(
          p,
          12,
          Paint()
            ..color = i == selected ? Colors.white : const Color(0xFF0A0C0E)
            ..style = PaintingStyle.stroke
            ..strokeWidth = i == selected ? 2.4 : 1.6,
        );
        final tp = TextPainter(
          text: TextSpan(
              text: '${i + 1}',
              style: const TextStyle(
                  color: S3Colors.accDark,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(_DlmsGraphPainter old) => true;
}

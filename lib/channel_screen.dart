// Tab CHANNEL mode DLMS — persis rancangan layar 1 (v22):
// strip IN A / IN B / OUT 1 / OUT 2 / MASTER + panel detail ber-chip fungsi.
// Semua fungsi hidup: PEQ, Routing, Crossover, Delay, Limiter, Fase.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'device_controller.dart';
import 'models.dart';
import 'regular_channel.dart';
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
      // Mode reguler: layar CHANNEL-nya sendiri (Gate/Compressor).
      return RegularChannelScreen(ctl: ctl);
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
      decoration: s3Raised(S3Colors.panel, radius: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: s3Raised(
                  sel == 4
                      ? S3Colors.capRed
                      : (sel < 2 ? S3Colors.blue : S3Colors.plate),
                  radius: 7,
                ),
                child: Text(_names[sel],
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: sel == 2 || sel == 3
                            ? S3Colors.accDark
                            : Colors.white)),
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
      elevation: active ? 5 : 2,
      shadowColor: active ? S3Colors.blue : Colors.black,
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
      final dly = isA ? d.inDlyA : d.inDlyB;
      final on = isA ? d.inOnA : d.inOnB;
      // Gain input diatur dari fader strip (kenop GAIN dobel dicabut);
      // panel ini khusus delay input + status aktif.
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DELAY INPUT',
              style: TextStyle(
                  color: S3Colors.dim, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              S3Knob(
                label: 'DELAY',
                valueText: '${fmtNum(dly, 1)} ms',
                frac: (dly / 100).clamp(0, 1).toDouble(),
                arcColor: const Color(0xFF6ED0E4),
                diameter: 150,
                onFrac: (f) => ctl.setInDelay(isA, f * 100, drag: true),
                onEnd: () => ctl.setInDelay(isA, dly),
              ),
              const SizedBox(width: 34),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _chipBtn(on ? 'AKTIF' : 'NONAKTIF', on,
                      () => ctl.setInOn(isA, !on)),
                  const SizedBox(height: 12),
                  const SizedBox(
                    width: 320,
                    child: Text(
                      'Gain input ini diatur dari fader strip-nya di kiri. Delay input (0–100 ms) menyelaraskan sumber sebelum masuk rantai DLMS.',
                      style: TextStyle(color: S3Colors.dim, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }
    if (sel == 4) {
      // Volume diatur dari fader strip MASTER (kenop VOLUME dobel dicabut);
      // MUTE & DIM jadi blok besar mengisi panel.
      Widget bigBlock(String label, bool active, Color activeColor,
          VoidCallback onTap) {
        return Expanded(
          child: Material(
            color: active ? activeColor : S3Colors.card,
            elevation: active ? 6 : 2,
            shadowColor: active ? activeColor : Colors.black,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Center(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: active ? Colors.white : S3Colors.dim)),
              ),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MASTER',
              style: TextStyle(
                  color: S3Colors.dim, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                bigBlock('MUTE', s.mute, S3Colors.muteRed,
                    () => ctl.setMute(!s.mute)),
                const SizedBox(width: 10),
                bigBlock(
                    'DIM', s.dim, S3Colors.blue, () => ctl.setDim(!s.dim)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Volume diatur dari fader strip MASTER di kiri — strip itu berlaku di semua mode.',
            style: TextStyle(color: S3Colors.dim, fontSize: 12.5),
          ),
        ],
      );
    }
    // OUT 1 / OUT 2
    final ch = sel - 2;
    final c = d.ch[ch];
    switch (chip) {
      case 'Routing':
        return _RoutingPanel(ctl: ctl, ch: ch, src: c.src);
      case 'Crossover':
        return _CrossoverPanel(ctl: ctl, ch: ch, c: c, d: d);
      case 'Delay':
        return _DelayPanel(ctl: ctl, ch: ch, ms: c.dly);
      case 'Limiter':
        return _LimiterPanel(ctl: ctl, ch: ch, lim: c.lim);
      case 'Fase':
        return _FasePanel(ctl: ctl, ch: ch, c: c);
      default:
        return _PeqPanel(
          ctl: ctl,
          ch: ch,
          chState: c,
          band: peqBand,
          onBand: (b) => setState(() => peqBand = b),
        );
    }
  }
}

const _tfNames = ['LR 12', 'LR 24', 'LR 48', 'BW 12', 'BW 24', 'BW 48'];

String _freqText(double f) => f >= 1000
    ? '${fmtNum(f / 1000, f >= 10000 ? 0 : 2)} kHz'
    : '${f.round()} Hz';

class _RoutingPanel extends StatelessWidget {
  final DeviceController ctl;
  final int ch;
  final int src;
  const _RoutingPanel({required this.ctl, required this.ch, required this.src});

  @override
  Widget build(BuildContext context) {
    const opts = [
      ('A', 'Input A saja'),
      ('B', 'Input B saja'),
      ('A+B', 'Jumlah A + B'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SUMBER KANAL',
            style: TextStyle(
                color: S3Colors.dim, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        // Blok sumber mengisi tinggi panel (dulu mungil di tengah — ruang
        // kosong di atas/bawahnya yang dikeluhkan user).
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                    child: Material(
                      color: src == i ? S3Colors.blue : S3Colors.card,
                      elevation: src == i ? 6 : 2,
                      shadowColor: src == i ? S3Colors.blue : Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => ctl.setChField(ch, 'src', '$i'),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(opts[i].$1,
                                style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: src == i
                                        ? Colors.white
                                        : S3Colors.txt)),
                            const SizedBox(height: 6),
                            Text(opts[i].$2,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: src == i
                                        ? Colors.white70
                                        : S3Colors.dim)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Routing memilih sinyal masuk yang diolah kanal ini. A+B menjumlahkan kedua input (mis. untuk subwoofer mono).',
          style: TextStyle(color: S3Colors.dim, fontSize: 12),
        ),
      ],
    );
  }
}

class _CrossoverPanel extends StatelessWidget {
  final DeviceController ctl;
  final int ch;
  final DlmsChState c;
  final DlmsState d; // untuk overlay kurva OUT 1 vs OUT 2
  const _CrossoverPanel(
      {required this.ctl, required this.ch, required this.c, required this.d});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('CROSSOVER',
                style: TextStyle(
                    color: S3Colors.dim,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            const Text('TIPE',
                style: TextStyle(color: S3Colors.dim, fontSize: 12)),
            const SizedBox(width: 8),
            Material(
              color: S3Colors.card,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: () =>
                    ctl.setChField(ch, 'tf', '${(c.tf + 1) % 6}'),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  child: Text(_tfNames[c.tf.clamp(0, 5)],
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // legenda overlay dua output
        Row(
          children: [
            _legend(const Color(0xFF52C76E), 'OUT 1'),
            const SizedBox(width: 14),
            _legend(const Color(0xFFB78CE0), 'OUT 2'),
            const SizedBox(width: 14),
            const Text('garis tebal = kanal yang sedang diedit',
                style: TextStyle(color: S3Colors.dim, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _XoverPainter(c: c, d: d, selCh: ch),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _xoToggle('HPF', c.hpfOn,
                () => ctl.setChField(ch, 'hpfOn', c.hpfOn ? '0' : '1')),
            const SizedBox(width: 10),
            S3Knob(
              label: 'HPF',
              valueText: _freqText(c.hpfF),
              frac: fracOfLog(c.hpfF, 20, 20000),
              arcColor: const Color(0xFFFAAC58),
              diameter: 84,
              onFrac: (f) => ctl.setChField(
                  ch, 'hpfF', valOfLog(f, 20, 20000).toStringAsFixed(1),
                  drag: true),
              onEnd: () => ctl.setChField(
                  ch, 'hpfF', c.hpfF.toStringAsFixed(1)),
            ),
            const SizedBox(width: 26),
            _xoToggle('LPF', c.lpfOn,
                () => ctl.setChField(ch, 'lpfOn', c.lpfOn ? '0' : '1')),
            const SizedBox(width: 10),
            S3Knob(
              label: 'LPF',
              valueText: _freqText(c.lpfF),
              frac: fracOfLog(c.lpfF, 20, 20000),
              arcColor: const Color(0xFF6ED0E4),
              diameter: 84,
              onFrac: (f) => ctl.setChField(
                  ch, 'lpfF', valOfLog(f, 20, 20000).toStringAsFixed(1),
                  drag: true),
              onEnd: () => ctl.setChField(
                  ch, 'lpfF', c.lpfF.toStringAsFixed(1)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _xoToggle(String label, bool on, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: on ? S3Colors.blue : S3Colors.card,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Text('$label ${on ? 'ON' : 'OFF'}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: on ? Colors.white : S3Colors.dim)),
          ),
        ),
      ),
    );
  }
}

/// Magnitudo pendekatan untuk gambar: BW orde o -> 1/sqrt(1+x^o);
/// LR orde o -> 1/(1+x^o). x = fc/f (HP) atau f/fc (LP).
double _xoMag(bool hp, double fc, int tf, double f) {
  final order = [2, 4, 8][tf % 3];
  final x = hp ? fc / f : f / fc;
  final xp = math.pow(x, order).toDouble();
  return tf < 3 ? 1 / (1 + xp) : 1 / math.sqrt(1 + xp);
}

class _XoverPainter extends CustomPainter {
  final DlmsChState c;
  final DlmsState d;
  final int selCh;
  _XoverPainter({required this.c, required this.d, required this.selCh});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(7)),
      Paint()..color = const Color(0xFF0F1114),
    );
    double yOf(double mag) =>
        14 + (1 - mag.clamp(0.0, 1.0)) * (size.height - 44);
    // garis penanda -3 / -6 / -12 dB
    for (final mag in [0.707, 0.5, 0.25]) {
      final y = yOf(mag);
      canvas.drawLine(Offset(8, y), Offset(size.width - 8, y),
          Paint()..color = const Color(0xFF232B36)..strokeWidth = 1);
    }
    // Gabungan filter AKTIF satu kanal (respons nyata kanal itu).
    Path combinedFor(DlmsChState cc) {
      final p = Path();
      const steps = 130;
      for ( var i = 0; i <= steps; i++) {
        final x = size.width * i / steps;
        final f = _xToF(x, size.width);
        var m = 1.0;
        if (cc.hpfOn) m *= _xoMag(true, cc.hpfF, cc.tf, f);
        if (cc.lpfOn) m *= _xoMag(false, cc.lpfF, cc.tf, f);
        final y = yOf(m);
        i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
      }
      return p;
    }

    // Kurva HPF & LPF SELALU digambar (terang bila ON, redup bila OFF)
    // agar titik potong crossover tetap terlihat — dulu kurva hilang total
    // saat filter mati dan grafik tampak kosong.
    Path curveFor(bool hp) {
      final p = Path();
      const steps = 130;
      for (var i = 0; i <= steps; i++) {
        final x = size.width * i / steps;
        final f = _xToF(x, size.width);
        final y = yOf(_xoMag(hp, hp ? c.hpfF : c.lpfF, c.tf, f));
        i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
      }
      return p;
    }

    canvas.drawPath(
        curveFor(true),
        Paint()
          ..color = const Color(0xFFFAAC58)
              .withValues(alpha: c.hpfOn ? 1 : 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);
    canvas.drawPath(
        curveFor(false),
        Paint()
          ..color = const Color(0xFF6ED0E4)
              .withValues(alpha: c.lpfOn ? 1 : 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);
    // penanda vertikal frekuensi potong + labelnya
    for (final (fc, isHp) in [(c.hpfF, true), (c.lpfF, false)]) {
      final x = _fToX(fc, size.width);
      canvas.drawLine(
          Offset(x, 6),
          Offset(x, size.height - 18),
          Paint()
            ..color = (isHp ? const Color(0xFFFAAC58) : const Color(0xFF6ED0E4))
                .withValues(alpha: 0.4)
            ..strokeWidth = 1);
      final tp = TextPainter(
        text: TextSpan(
            text: isHp ? 'HPF' : 'LPF',
            style: TextStyle(
                color: isHp
                    ? const Color(0xFFFAAC58)
                    : const Color(0xFF6ED0E4),
                fontSize: 9,
                fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + 3, 6));
    }
    // Overlay respons OUT 1 vs OUT 2 — di sinilah titik potong antar
    // output terlihat (maksud "grafik potong" user): hijau = OUT 1,
    // ungu = OUT 2, yang sedang diedit digambar lebih tebal.
    for (var i = 0; i < 2; i++) {
      canvas.drawPath(
        combinedFor(d.ch[i]),
        Paint()
          ..color = (i == 0
                  ? const Color(0xFF52C76E)
                  : const Color(0xFFB78CE0))
              .withValues(alpha: i == selCh ? 1 : 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == selCh ? 3.0 : 2.0,
      );
    }
    // label frekuensi
    for (final f in [20.0, 100.0, 1000.0, 10000.0, 20000.0]) {
      final x = _fToX(f, size.width);
      final tp = TextPainter(
        text: TextSpan(
            text: f >= 1000 ? '${(f / 1000).round()}k' : '${f.round()}',
            style: const TextStyle(color: S3Colors.dim, fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - 14));
    }
  }

  @override
  bool shouldRepaint(_XoverPainter old) => true;
}

class _DelayPanel extends StatelessWidget {
  final DeviceController ctl;
  final int ch;
  final double ms;
  const _DelayPanel({required this.ctl, required this.ch, required this.ms});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DELAY KANAL',
            style: TextStyle(
                color: S3Colors.dim, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            S3Knob(
              label: 'DELAY',
              valueText: '${fmtNum(ms, 2)} ms',
              frac: (ms / 20).clamp(0, 1).toDouble(),
              arcColor: const Color(0xFF6ED0E4),
              diameter: 170,
              onFrac: (f) => ctl.setChField(
                  ch, 'dly', (f * 20).toStringAsFixed(2),
                  drag: true),
              onEnd: () => ctl.setChField(ch, 'dly', ms.toStringAsFixed(2)),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Setara jarak ≈ ${fmtNum(ms * 34.3, 0)} cm.\nUntuk menyelaraskan waktu tiba suara antar speaker (time alignment). Perubahan delay kini bebas bunyi "ciitt" berkat crossfade tap di firmware.',
                  style: const TextStyle(color: S3Colors.dim, fontSize: 12.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LimiterPanel extends StatelessWidget {
  final DeviceController ctl;
  final int ch;
  final double lim;
  const _LimiterPanel({required this.ctl, required this.ch, required this.lim});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('LIMITER KANAL',
            style: TextStyle(
                color: S3Colors.dim, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            S3Knob(
              label: 'AMBANG',
              valueText: fmtDb(lim),
              frac: ((lim + 24) / 24).clamp(0, 1).toDouble(),
              arcColor: S3Colors.red,
              diameter: 170,
              onFrac: (f) => ctl.setChField(
                  ch, 'lim', (f * 24 - 24).toStringAsFixed(2),
                  drag: true),
              onEnd: () => ctl.setChField(ch, 'lim', lim.toStringAsFixed(2)),
            ),
            const SizedBox(width: 30),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Pembatas per kanal (soft-clip tanh). Sinyal di atas ambang dijepit halus agar power dan speaker aman dari puncak berlebih.',
                  style: TextStyle(color: S3Colors.dim, fontSize: 12.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FasePanel extends StatelessWidget {
  final DeviceController ctl;
  final int ch;
  final DlmsChState c;
  const _FasePanel({required this.ctl, required this.ch, required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('FASE & STATUS KANAL',
            style: TextStyle(
                color: S3Colors.dim, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Expanded(
              child: Material(
                color: c.pol ? S3Colors.muteRed : S3Colors.card,
                elevation: c.pol ? 6 : 2,
                shadowColor: c.pol ? S3Colors.muteRed : Colors.black,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () =>
                      ctl.setChField(ch, 'pol', c.pol ? '0' : '1'),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(c.pol ? 'TERBALIK 180°' : 'NORMAL 0°',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: c.pol ? Colors.white : S3Colors.txt)),
                        const SizedBox(height: 4),
                        const Text('Ketuk untuk membalik fase',
                            style: TextStyle(
                                fontSize: 11.5, color: S3Colors.dim)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Material(
                color: c.on ? S3Colors.blue : S3Colors.card,
                elevation: c.on ? 6 : 2,
                shadowColor: c.on ? S3Colors.blue : Colors.black,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => ctl.setChOn(ch, !c.on),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(c.on ? 'KANAL AKTIF' : 'KANAL MATI',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: c.on ? Colors.white : S3Colors.txt)),
                        const SizedBox(height: 4),
                        const Text('Sama dengan tombol MUTE di strip',
                            style: TextStyle(
                                fontSize: 11.5, color: S3Colors.dim)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ],
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

// Tab CHANNEL mode DLMS — persis rancangan layar 1 (v22):
// strip IN A / IN B / OUT 1 / OUT 2 / MASTER + panel detail ber-chip fungsi.
// Semua fungsi hidup: PEQ, Routing, Crossover, Delay, Limiter, Fase.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'device_controller.dart';
import 'models.dart';
import 'regular_channel.dart';
import 'theme.dart';
import 'widgets_param.dart';
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
      final gain = isA ? d.inGainA : d.inGainB;
      // Panel PADAT (rombakan total): status tersegmentasi + slider delay
      // presisi + ringkasan nyata. Gain tetap dari fader strip — di sini
      // info baca-saja, bukan kontrol dobel.
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ParamSegmented(
              label: 'STATUS',
              options: const ['NONAKTIF', 'AKTIF'],
              selected: on ? 1 : 0,
              onSelect: (i) => ctl.setInOn(isA, i == 1),
            ),
            ParamSlider(
              label: 'DELAY',
              valueText: '${fmtNum(dly, 1)} ms',
              value: dly,
              min: 0,
              max: 100,
              color: const Color(0xFF6ED0E4),
              onChanged: (v) => ctl.setInDelay(isA, v, drag: true),
              onEnd: () => ctl.setInDelay(isA, dly),
            ),
            const SectionHead('RINGKASAN INPUT'),
            InfoRow(label: 'GAIN', value: '${fmtDb(gain)} — dari fader strip'),
            InfoRow(label: 'JARAK', value: '≈ ${fmtNum(dly * 34.3, 0)} cm'),
            InfoRow(
                label: 'SAMPEL',
                value: '${(dly * 48).round()} sampel @ 48 kHz'),
            const SizedBox(height: 8),
            const Text(
              'Delay input menyelaraskan sumber sebelum masuk rantai DLMS (mis. input B dari perangkat yang lebih lambat).',
              style: TextStyle(color: S3Colors.dim, fontSize: 12),
            ),
          ],
        ),
      );
    }
    if (sel == 4) {
      // Panel master PADAT: slider volume presisi + mute/dim tersegmentasi +
      // ringkasan input. Fader strip tetap jalan — ini editor presisinya,
      // pola yang sama seperti EQ (grafik + strip + angka).
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHead('SPEKTRUM KELUARAN'),
            const SizedBox(height: 4),
            RtaBox(rta: ctl.rta),
            const SizedBox(height: 6),
            ParamSlider(
              label: 'VOLUME',
              valueText: fmtDb(ctl.volDb),
              value: ctl.volDb,
              min: -60,
              max: 0,
              color: S3Colors.red,
              onChanged: (v) => ctl.setVolDb(v, drag: true),
              onEnd: () => ctl.setVolDb(ctl.volDb),
            ),
            ParamSegmented(
              label: 'MUTE',
              options: const ['OFF', 'ON'],
              selected: s.mute ? 1 : 0,
              onSelect: (i) => ctl.setMute(i == 1),
            ),
            ParamSegmented(
              label: 'DIM',
              options: const ['OFF', 'ON'],
              selected: s.dim ? 1 : 0,
              onSelect: (i) => ctl.setDim(i == 1),
            ),
            const SectionHead('RINGKASAN'),
            const InfoRow(label: 'MODE', value: 'DLMS'),
            InfoRow(
                label: 'IN A',
                value:
                    '${d.inOnA ? 'Aktif' : 'Mati'} · ${fmtDb(d.inGainA)} · delay ${fmtNum(d.inDlyA, 1)} ms'),
            InfoRow(
                label: 'IN B',
                value:
                    '${d.inOnB ? 'Aktif' : 'Mati'} · ${fmtDb(d.inGainB)} · delay ${fmtNum(d.inDlyB, 1)} ms'),
          ],
        ),
      );
    }
    // OUT 1 / OUT 2
    final ch = sel - 2;
    final c = d.ch[ch];
    switch (chip) {
      case 'Routing':
        return _RoutingPanel(ctl: ctl, ch: ch, c: c);
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
  final DlmsChState c;
  const _RoutingPanel({required this.ctl, required this.ch, required this.c});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ParamSegmented(
            label: 'SUMBER',
            options: const ['A', 'B', 'A+B'],
            selected: c.src.clamp(0, 2),
            onSelect: (i) => ctl.setChField(ch, 'src', '$i'),
            height: 44,
          ),
          const SectionHead('RINGKASAN KANAL'),
          InfoRow(label: 'HPF', value: c.hpfOn ? _freqText(c.hpfF) : 'Mati'),
          InfoRow(label: 'LPF', value: c.lpfOn ? _freqText(c.lpfF) : 'Mati'),
          InfoRow(label: 'TIPE', value: _tfNames[c.tf.clamp(0, 5)]),
          InfoRow(
              label: 'PEQ',
              value: c.peqOn
                  ? c.peq.map((g) => fmtDb(g)).join('  ·  ')
                  : 'Mati'),
          InfoRow(label: 'DELAY', value: '${fmtNum(c.dly, 2)} ms'),
          InfoRow(label: 'LIMITER', value: fmtDb(c.lim)),
          InfoRow(
              label: 'FASE', value: c.pol ? 'Terbalik 180°' : 'Normal 0°'),
          InfoRow(label: 'STATUS', value: c.on ? 'Aktif' : 'Mati'),
          const SizedBox(height: 8),
          const Text(
            'A+B menjumlahkan kedua input (mis. untuk subwoofer mono). Detail tiap fungsi ada di chip-nya masing-masing.',
            style: TextStyle(color: S3Colors.dim, fontSize: 12),
          ),
        ],
      ),
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('CROSSOVER',
                  style: TextStyle(
                      color: S3Colors.dim,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              _legend(const Color(0xFF52C76E), 'OUT 1'),
              const SizedBox(width: 12),
              _legend(const Color(0xFFB78CE0), 'OUT 2'),
              const SizedBox(width: 12),
              const Text('garis tebal = kanal yang sedang diedit',
                  style: TextStyle(color: S3Colors.dim, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          // Grafik titik potong OUT 1 vs OUT 2 (permintaan user) — tinggi
          // tetap agar tidak lenyap di layar pendek; panel bisa digulir.
          SizedBox(
            height: 190,
            child: CustomPaint(
              size: Size.infinite,
              painter: _XoverPainter(c: c, d: d, selCh: ch),
            ),
          ),
          ParamSegmented(
            label: 'TIPE',
            options: _tfNames,
            selected: c.tf.clamp(0, 5),
            onSelect: (i) => ctl.setChField(ch, 'tf', '$i'),
            height: 34,
          ),
          ParamSegmented(
            label: 'HPF',
            options: const ['OFF', 'ON'],
            selected: c.hpfOn ? 1 : 0,
            onSelect: (i) => ctl.setChField(ch, 'hpfOn', i == 1 ? '1' : '0'),
          ),
          ParamSlider(
            label: 'FREQ HPF',
            valueText: _freqText(c.hpfF),
            value: fracOfLog(c.hpfF, 20, 20000),
            min: 0,
            max: 1,
            color: const Color(0xFFFAAC58),
            enabled: c.hpfOn,
            onChanged: (f) => ctl.setChField(
                ch, 'hpfF', valOfLog(f, 20, 20000).toStringAsFixed(1),
                drag: true),
            onEnd: () => ctl.setChField(ch, 'hpfF', c.hpfF.toStringAsFixed(1)),
          ),
          ParamSegmented(
            label: 'LPF',
            options: const ['OFF', 'ON'],
            selected: c.lpfOn ? 1 : 0,
            onSelect: (i) => ctl.setChField(ch, 'lpfOn', i == 1 ? '1' : '0'),
          ),
          ParamSlider(
            label: 'FREQ LPF',
            valueText: _freqText(c.lpfF),
            value: fracOfLog(c.lpfF, 20, 20000),
            min: 0,
            max: 1,
            color: const Color(0xFF6ED0E4),
            enabled: c.lpfOn,
            onChanged: (f) => ctl.setChField(
                ch, 'lpfF', valOfLog(f, 20, 20000).toStringAsFixed(1),
                drag: true),
            onEnd: () => ctl.setChField(ch, 'lpfF', c.lpfF.toStringAsFixed(1)),
          ),
        ],
      ),
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
    const quick = [0.0, 0.5, 1.0, 2.0, 5.0, 10.0, 15.0, 20.0];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmtNum(ms, 2),
                  style: const TextStyle(
                      fontSize: 42, fontWeight: FontWeight.bold, height: 1)),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text('ms',
                    style: TextStyle(
                        color: S3Colors.dim,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text('≈ ${fmtNum(ms * 34.3, 0)} cm · ${(ms * 48).round()} sampel',
                  style: const TextStyle(color: S3Colors.dim, fontSize: 12.5)),
            ],
          ),
          ParamSlider(
            label: 'DELAY',
            valueText: '${fmtNum(ms, 2)} ms',
            value: ms,
            min: 0,
            max: 20,
            color: const Color(0xFF6ED0E4),
            onChanged: (v) =>
                ctl.setChField(ch, 'dly', v.toStringAsFixed(2), drag: true),
            onEnd: () => ctl.setChField(ch, 'dly', ms.toStringAsFixed(2)),
          ),
          const SectionHead('SET CEPAT (ms)'),
          const SizedBox(height: 4),
          Row(
            children: [
              for (var i = 0; i < quick.length; i++)
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(right: i < quick.length - 1 ? 6 : 0),
                    child: Material(
                      color: (ms - quick[i]).abs() < 0.005
                          ? S3Colors.blue
                          : S3Colors.card,
                      elevation: (ms - quick[i]).abs() < 0.005 ? 4 : 1.5,
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        onTap: () => ctl.setChField(
                            ch, 'dly', quick[i].toStringAsFixed(2)),
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 36,
                          child: Center(
                            child: Text(
                                fmtNum(quick[i], quick[i] % 1 == 0 ? 0 : 1),
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: (ms - quick[i]).abs() < 0.005
                                        ? Colors.white
                                        : S3Colors.dim)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SectionHead('KETERANGAN'),
          const Text(
            'Delay menyelaraskan waktu tiba suara antar speaker (time alignment): 1 ms ≈ 34,3 cm jarak tempuh suara. Perubahan delay bebas bunyi "ciitt" berkat crossfade tap di firmware.',
            style: TextStyle(color: S3Colors.dim, fontSize: 12.5),
          ),
        ],
      ),
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ParamSlider(
            label: 'AMBANG',
            valueText: fmtDb(lim),
            value: lim,
            min: -24,
            max: 0,
            color: S3Colors.red,
            onChanged: (v) =>
                ctl.setChField(ch, 'lim', v.toStringAsFixed(2), drag: true),
            onEnd: () => ctl.setChField(ch, 'lim', lim.toStringAsFixed(2)),
          ),
          const SectionHead('KURVA TRANSFER (masukan → keluaran)'),
          const SizedBox(height: 4),
          SizedBox(
            height: 132,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LimPainter(lim: lim),
            ),
          ),
          InfoRow(
              label: 'AMBANG',
              value: '${fmtDb(lim)} — puncak di atas ini diturunkan'),
          InfoRow(
              label: 'REDUKSI',
              value:
                  'Puncak 0 dBFS diturunkan maks ≈ ${fmtNum(-lim, 1)} dB'),
          const SizedBox(height: 8),
          const Text(
            'Peak limiter per kanal (firmware v5.2.2): gain diturunkan sesaat hanya saat puncak melewati ambang (attack/release), bentuk gelombang utuh — bukan saturator. Dulu tanh mentah yang mengukir gelombang sampai berbunyi noise saat ambang diturunkan.',
            style: TextStyle(color: S3Colors.dim, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Kurva transfer peak limiter: keluaran mengikuti masukan secara lurus
/// sampai ambang (garis putus-putus merah), di atasnya rata — gain diturunkan
/// sesaat oleh firmware (v5.2.2), gelombang tidak diukir ulang.
class _LimPainter extends CustomPainter {
  final double lim;
  _LimPainter({required this.lim});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF101216);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Offset.zero & size, const Radius.circular(6)),
        bg);
    final w = size.width, h = size.height;
    double xOf(double x) => (x / 1.25 * 0.5 + 0.5) * w;
    double yOf(double y) => (0.5 - y / 1.25 * 0.5) * h;
    final grid = Paint()
      ..color = const Color(0xFF232830)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(xOf(0), 6), Offset(xOf(0), h - 6), grid);
    canvas.drawLine(Offset(6, yOf(0)), Offset(w - 6, yOf(0)), grid);
    // garis ambang (putus-putus sederhana: segmen pendek)
    final t = math.pow(10, lim / 20).toDouble();
    final thr = Paint()
      ..color = const Color(0xFFF47068)
      ..strokeWidth = 1.2;
    for (double y = 8; y < h - 8; y += 9) {
      canvas.drawLine(Offset(xOf(t), y), Offset(xOf(t), y + 5), thr);
      canvas.drawLine(Offset(xOf(-t), y), Offset(xOf(-t), y + 5), thr);
    }
    // transfer: y = x dijepit di ±ambang (linear)
    final path = Path();
    for (var i = 0; i <= 120; i++) {
      final x = -1.25 + 2.5 * i / 120;
      final y = x.clamp(-t, t).toDouble();
      final px = xOf(x), py = yOf(y);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF6ED0E4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_LimPainter old) => old.lim != lim;
}

class _FasePanel extends StatelessWidget {
  final DeviceController ctl;
  final int ch;
  final DlmsChState c;
  const _FasePanel({required this.ctl, required this.ch, required this.c});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ParamSegmented(
            label: 'FASE',
            options: const ['NORMAL 0°', 'TERBALIK 180°'],
            selected: c.pol ? 1 : 0,
            onSelect: (i) => ctl.setChField(ch, 'pol', i == 1 ? '1' : '0'),
            height: 42,
          ),
          ParamSegmented(
            label: 'STATUS',
            options: const ['MATI', 'AKTIF'],
            selected: c.on ? 1 : 0,
            onSelect: (i) => ctl.setChOn(ch, i == 1),
            height: 42,
          ),
          const SectionHead('RINGKASAN KANAL'),
          InfoRow(
              label: 'SUMBER',
              value: const ['A', 'B', 'A+B'][c.src.clamp(0, 2)]),
          InfoRow(label: 'GAIN', value: fmtDb(c.gain)),
          InfoRow(label: 'HPF', value: c.hpfOn ? _freqText(c.hpfF) : 'Mati'),
          InfoRow(label: 'LPF', value: c.lpfOn ? _freqText(c.lpfF) : 'Mati'),
          InfoRow(label: 'DELAY', value: '${fmtNum(c.dly, 2)} ms'),
          InfoRow(label: 'LIMITER', value: fmtDb(c.lim)),
          const SizedBox(height: 8),
          const Text(
            'Fase terbalik membalik polaritas kanal ini 180° — berguna bila satu speaker terpasang terbalik, atau untuk mencocokkan sub dengan top.',
            style: TextStyle(color: S3Colors.dim, fontSize: 12),
          ),
        ],
      ),
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
    return SingleChildScrollView(
      child: Column(
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
        SizedBox(
          height: 168,
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
        const SizedBox(height: 10),
        // Slider gain per band: pasangan presisi dari seretan titik di
        // grafik (pola editor EQ profesional: grafik + tabel angka) —
        // mengisi panel dan memudahkan setelan halus di HP.
        for (var i = 0; i < 3; i++)
          ParamSlider(
            label: 'B${i + 1} ${_PeqPanel._freqLabel(dlmsBandFreqs[i])}',
            valueText: fmtDb(gains[i]),
            value: gains[i],
            min: -15,
            max: 15,
            color: dlmsBandColors[i],
            enabled: chState.peqOn,
            onChanged: (v) {
              onBand(i);
              ctl.setChPeqGain(ch, i, v, drag: true);
            },
            onEnd: () => ctl.setChPeqGain(ch, i, gains[i]),
          ),
        const SizedBox(height: 6),
        // Baris petunjuk + reset band terpilih.
        Row(
          children: [
            const Text('Seret titik di grafik, atau geser slider band di atas',
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
      ),
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
    // spektrum hijau-kuning-merah (gradien pada tinggi penuh plot)
    if (rta.length >= 31) {
      final bw = (size.width - 40) / 31;
      final barPaint = Paint()
        ..shader = rtaGradient(
            Rect.fromLTWH(36, 18, size.width - 40, size.height - 44),
            alpha: 0.55);
      for (var i = 0; i < 31; i++) {
        final frac = ((rta[i] + 60) / 54).clamp(0.0, 1.0).toDouble();
        final h = frac * (size.height - 44);
        final x = 36 + i * bw;
        final y = size.height - 26 - h;
        canvas.drawRect(Rect.fromLTWH(x, y, bw - 2, h), barPaint);
        canvas.drawRect(
            Rect.fromLTWH(x, y, bw - 2, 5), Paint()..color = rtaColorAt(frac));
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

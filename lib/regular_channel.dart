import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'device_controller.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets_param.dart';
import 'widgets_strip.dart';

/// CHANNEL mode REGULER mengikuti rancangan layar 2: strip INPUT USB /
/// OUT 1 / OUT 2 / MASTER + panel dinamika (Noise Gate / Compressor dengan
/// meter IN-GR-OUT dan grafik transfer).
///
/// Pemetaan strip ke rantai reguler firmware: INPUT USB = preamp,
/// OUT 1/2 = trim L/R, MASTER = volume. Karena rantai reguler tidak punya
/// mute per strip, tombol kaki diberi fungsi asli masing-masing:
/// BYPASS (input), FASE (output), MUTE (master) — tata letak sama persis
/// dengan rancangan, tanpa tombol pura-pura.
class RegularChannelScreen extends StatefulWidget {
  final DeviceController ctl;
  const RegularChannelScreen({super.key, required this.ctl});

  @override
  State<RegularChannelScreen> createState() => _RegularChannelScreenState();
}

class _RegularChannelScreenState extends State<RegularChannelScreen> {
  int sel = 0; // 0 INPUT USB, 1 OUT 1, 2 OUT 2, 3 MASTER
  String func = 'Compressor';
  static const _names = ['INPUT USB', 'OUT 1', 'OUT 2', 'MASTER'];
  static const _trimScale = ['+12', '+9', '+6', '+3', '0', '-3', '-6', '-9', '-12'];
  static const _volScale = ['0', '-7', '-15', '-22', '-30', '-37', '-45', '-52', '-60'];

  DeviceController get ctl => widget.ctl;

  String _fmt(double v) => fmtNum(v, 1);

  @override
  Widget build(BuildContext context) {
    final s = ctl.state;
    if (s == null) return const SizedBox.shrink();
    final mL = ctl.meter.l, mR = ctl.meter.r;
    final strips = <Widget>[
      DesignStrip(
        name: 'INPUT USB',
        gainText: '${_fmt(s.preamp)} dB',
        faderDb: s.preamp,
        meterFrac: math.max(mL, mR),
        selected: sel == 0,
        muted: s.bypass,
        master: false,
        dbMin: -12,
        dbMax: 12,
        scaleLabels: _trimScale,
        footLabel: 'BYPASS',
        footActiveColor: S3Colors.blue,
        onTap: () => setState(() => sel = 0),
        onFaderDb: (db) => ctl.setParam('preamp', db, drag: true),
        onFaderEnd: () => ctl.setParam('preamp', s.preamp),
        onMute: () => ctl.setParam('bypass', s.bypass ? 0 : 1),
      ),
      DesignStrip(
        name: 'OUT 1',
        gainText: '${_fmt(s.trimL)} dB',
        faderDb: s.trimL,
        meterFrac: mL,
        selected: sel == 1,
        muted: s.polL,
        master: false,
        dbMin: -12,
        dbMax: 12,
        scaleLabels: _trimScale,
        footLabel: 'FASE',
        footActiveColor: S3Colors.blue,
        onTap: () => setState(() => sel = 1),
        onFaderDb: (db) => ctl.setParam('trimL', db, drag: true),
        onFaderEnd: () => ctl.setParam('trimL', s.trimL),
        onMute: () => ctl.setParam('polL', s.polL ? 0 : 1),
      ),
      DesignStrip(
        name: 'OUT 2',
        gainText: '${_fmt(s.trimR)} dB',
        faderDb: s.trimR,
        meterFrac: mR,
        selected: sel == 2,
        muted: s.polR,
        master: false,
        dbMin: -12,
        dbMax: 12,
        scaleLabels: _trimScale,
        footLabel: 'FASE',
        footActiveColor: S3Colors.blue,
        onTap: () => setState(() => sel = 2),
        onFaderDb: (db) => ctl.setParam('trimR', db, drag: true),
        onFaderEnd: () => ctl.setParam('trimR', s.trimR),
        onMute: () => ctl.setParam('polR', s.polR ? 0 : 1),
      ),
      DesignStrip(
        name: 'MASTER',
        gainText: ctl.meter.clip ? 'CLIP' : fmtDb(ctl.volDb),
        faderDb: ctl.volDb,
        meterFrac: math.max(mL, mR),
        selected: sel == 3,
        muted: s.mute,
        master: true,
        dbMin: -60,
        dbMax: 0,
        scaleLabels: _volScale,
        onTap: () => setState(() => sel = 3),
        onFaderDb: (db) => ctl.setVolDb(db.clamp(-60, 0).toDouble(), drag: true),
        onFaderEnd: () => ctl.setVolDb(ctl.volDb),
        onMute: () => ctl.setMute(!s.mute),
      ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < strips.length; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
            child: SizedBox(width: i == 0 ? 128 : 112, child: strips[i]),
          ),
        const SizedBox(width: 10),
        Expanded(child: _detail(s)),
      ],
    );
  }

  Widget _detail(DspState s) {
    return Container(
      decoration: s3Raised(S3Colors.panel, radius: 9),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: sel == 3
                      ? S3Colors.capRed
                      : (sel == 0 ? S3Colors.blue : S3Colors.plate),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(_names[sel],
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: sel == 1 || sel == 2
                            ? S3Colors.accDark
                            : Colors.white)),
              ),
              const SizedBox(width: 12),
              if (sel == 0)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in const ['Noise Gate', 'Compressor'])
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Material(
                              color: func == f
                                  ? S3Colors.blue
                                  : S3Colors.card,
                              borderRadius: BorderRadius.circular(6),
                              child: InkWell(
                                onTap: () => setState(() => func = f),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 13, vertical: 8),
                                  child: Text(f,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: func == f
                                              ? Colors.white
                                              : S3Colors.dim)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: _detailBody(s)),
        ],
      ),
    );
  }

  Widget _detailBody(DspState s) {
    switch (sel) {
      case 1:
        return _trimPanel(s, true);
      case 2:
        return _trimPanel(s, false);
      case 3:
        return _masterPanel(s);
      default:
        return func == 'Noise Gate' ? _gatePanel(s) : _compPanel(s);
    }
  }

  Widget _onToggle(String label, bool on, VoidCallback onTap) {
    return Material(
      color: on ? S3Colors.blue : S3Colors.card,
      elevation: on ? 5 : 2,
      shadowColor: on ? S3Colors.blue : Colors.black,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text('$label ${on ? 'ON' : 'OFF'}',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: on ? Colors.white : S3Colors.dim)),
        ),
      ),
    );
  }

  Widget _trimPanel(DspState s, bool left) {
    final trim = left ? s.trimL : s.trimR;
    final pol = left ? s.polL : s.polR;
    final dly = left ? s.dlyL : s.dlyR;
    final lvl = left ? ctl.meter.l : ctl.meter.r;
    // Editor output PADAT (rombakan total): trim presisi + DELAY output
    // (dlyL/dlyR — parameter nyata yang belum pernah tampil di aplikasi) +
    // fase tersegmentasi + meter level kanal ini.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ParamSlider(
            label: 'TRIM',
            valueText: fmtDb(trim),
            value: trim,
            min: -12,
            max: 12,
            color: S3Colors.plate,
            onChanged: (v) =>
                ctl.setParam(left ? 'trimL' : 'trimR', v, drag: true),
            onEnd: () => ctl.setParam(left ? 'trimL' : 'trimR', trim),
          ),
          ParamSlider(
            label: 'DELAY',
            valueText: '${fmtNum(dly, 1)} ms',
            value: dly,
            min: 0,
            max: 20,
            color: const Color(0xFF6ED0E4),
            onChanged: (v) =>
                ctl.setParam(left ? 'dlyL' : 'dlyR', v, drag: true),
            onEnd: () => ctl.setParam(left ? 'dlyL' : 'dlyR', dly),
          ),
          ParamSegmented(
            label: 'FASE',
            options: const ['NORMAL 0°', 'TERBALIK 180°'],
            selected: pol ? 1 : 0,
            onSelect: (i) =>
                ctl.setParam(left ? 'polL' : 'polR', i.toDouble()),
          ),
          const SectionHead('LEVEL KANAL INI'),
          const SizedBox(height: 4),
          _hMeter(lvl),
          const SizedBox(height: 8),
          Text(
            'Delay output menyelaraskan waktu tiba antara OUT 1 dan OUT 2 (di sini ≈ ${fmtNum(dly * 34.3, 0)} cm). Fase membalik polaritas 180° — berguna bila salah satu speaker terpasang terbalik.',
            style: const TextStyle(color: S3Colors.dim, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Meter level horizontal untuk satu kanal (dari meter.l / meter.r).
  Widget _hMeter(double level) {
    final frac = level.clamp(0, 1).toDouble();
    final color = frac > 0.89
        ? const Color(0xFFF47068)
        : (frac > 0.7 ? const Color(0xFFF8CD37) : const Color(0xFF34C76E));
    return Row(
      children: [
        const SizedBox(
          width: 96,
          child: Text('LEVEL',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: S3Colors.dim)),
        ),
        Expanded(
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF101216),
              border: Border.all(color: S3Colors.line),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: frac,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 88,
          child: Text('${(frac * 100).round()} %',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _masterPanel(DspState s) {
    // Panel mastering PADAT: volume presisi + mute/dim + loudness + cek
    // mono + width + balance — semua parameter master rantai reguler dalam
    // satu panel (dulu cuma dua tombol kecil di ruang kosong besar).
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          ParamSegmented(
            label: 'LOUDNESS',
            options: const ['OFF', 'ON'],
            selected: s.loud ? 1 : 0,
            onSelect: (i) => ctl.setParam('loud', i.toDouble()),
          ),
          ParamSegmented(
            label: 'CEK MONO',
            options: const ['OFF', 'ON'],
            selected: s.mono ? 1 : 0,
            onSelect: (i) => ctl.setParam('mono', i.toDouble()),
          ),
          ParamSlider(
            label: 'WIDTH',
            valueText: fmtNum(s.width, 2),
            value: s.width,
            min: 0,
            max: 2,
            color: const Color(0xFFB78CE0),
            onChanged: (v) => ctl.setParam('width', v, drag: true),
            onEnd: () => ctl.setParam('width', s.width),
          ),
          ParamSlider(
            label: 'BALANCE',
            valueText: s.balance == 0
                ? 'TENGAH'
                : (s.balance < 0
                    ? 'KIRI ${fmtNum(-s.balance * 100, 0)}'
                    : 'KANAN ${fmtNum(s.balance * 100, 0)}'),
            value: s.balance,
            min: -1,
            max: 1,
            color: const Color(0xFFFAAC58),
            onChanged: (v) => ctl.setParam('balance', v, drag: true),
            onEnd: () => ctl.setParam('balance', s.balance),
          ),
          const SizedBox(height: 4),
          const Text(
            'Width 1,00 = stereo normal (0 = mono, 2 = ekstra lebar). Loudness menebalkan bass/treble di volume kecil; Cek Mono menggabung L+R untuk memeriksa kompatibilitas mono.',
            style: TextStyle(color: S3Colors.dim, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _gatePanel(DspState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('NOISE GATE',
                style: TextStyle(
                    color: S3Colors.dim,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            _onToggle('GATE', s.gateOn,
                () => ctl.setParam('gateOn', s.gateOn ? 0 : 1)),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _GatePainter(thr: s.gateThr),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            S3Knob(
              label: 'THRESHOLD',
              valueText: fmtDb(s.gateThr),
              frac: ((s.gateThr + 80) / 80).clamp(0, 1).toDouble(),
              arcColor: const Color(0xFFFAAC58),
              diameter: 84,
              onFrac: (f) =>
                  ctl.setParam('gateThr', f * 80 - 80, drag: true),
              onEnd: () => ctl.setParam('gateThr', s.gateThr),
            ),
            const SizedBox(width: 22),
            S3Knob(
              label: 'ATTACK',
              valueText: '${fmtNum(s.gateAtk, 1)} ms',
              frac: fracOfLog(s.gateAtk, 0.1, 100),
              arcColor: S3Colors.yellow,
              diameter: 84,
              onFrac: (f) => ctl.setParam(
                  'gateAtk', valOfLog(f, 0.1, 100),
                  drag: true),
              onEnd: () => ctl.setParam('gateAtk', s.gateAtk),
            ),
            const SizedBox(width: 22),
            S3Knob(
              label: 'RELEASE',
              valueText: '${fmtNum(s.gateRel, 0)} ms',
              frac: fracOfLog(s.gateRel, 10, 1000),
              arcColor: const Color(0xFF6ED0E4),
              diameter: 84,
              onFrac: (f) => ctl.setParam(
                  'gateRel', valOfLog(f, 10, 1000),
                  drag: true),
              onEnd: () => ctl.setParam('gateRel', s.gateRel),
            ),
          ],
        ),
      ],
    );
  }

  Widget _compPanel(DspState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('COMPRESSOR',
                style: TextStyle(
                    color: S3Colors.dim,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            _onToggle('KOMPRESOR', s.compOn,
                () => ctl.setParam('compOn', s.compOn ? 0 : 1)),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _vMeter('IN', ctl.meter.l, S3Colors.meterGreen),
              const SizedBox(width: 10),
              _vMeter('GR', (ctl.meter.gr / 12).clamp(0, 1).toDouble(),
                  const Color(0xFFF8CD37)),
              const SizedBox(width: 10),
              _vMeter('OUT', ctl.meter.r, S3Colors.meterGreen),
              const SizedBox(width: 16),
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _CompPainter(thr: s.compThr, ratio: s.compRatio),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              S3Knob(
                label: 'THRESHOLD',
                valueText: fmtDb(s.compThr),
                frac: ((s.compThr + 60) / 60).clamp(0, 1).toDouble(),
                arcColor: const Color(0xFFFAAC58),
                diameter: 84,
                onFrac: (f) =>
                    ctl.setParam('compThr', f * 60 - 60, drag: true),
                onEnd: () => ctl.setParam('compThr', s.compThr),
              ),
              const SizedBox(width: 20),
              S3Knob(
                label: 'RATIO',
                valueText: '${fmtNum(s.compRatio, 1)} : 1',
                frac: ((s.compRatio - 1) / 19).clamp(0, 1).toDouble(),
                arcColor: S3Colors.yellow,
                diameter: 84,
                onFrac: (f) =>
                    ctl.setParam('compRatio', f * 19 + 1, drag: true),
                onEnd: () => ctl.setParam('compRatio', s.compRatio),
              ),
              const SizedBox(width: 20),
              S3Knob(
                label: 'ATTACK',
                valueText: '${fmtNum(s.compAtk, 0)} ms',
                frac: fracOfLog(s.compAtk, 0.1, 300),
                arcColor: const Color(0xFF6ED0E4),
                diameter: 84,
                onFrac: (f) => ctl.setParam(
                    'compAtk', valOfLog(f, 0.1, 300),
                    drag: true),
                onEnd: () => ctl.setParam('compAtk', s.compAtk),
              ),
              const SizedBox(width: 20),
              S3Knob(
                label: 'RELEASE',
                valueText: '${fmtNum(s.compRel, 0)} ms',
                frac: fracOfLog(s.compRel, 10, 1000),
                arcColor: const Color(0xFF7EE2A8),
                diameter: 84,
                onFrac: (f) => ctl.setParam(
                    'compRel', valOfLog(f, 10, 1000),
                    drag: true),
                onEnd: () => ctl.setParam('compRel', s.compRel),
              ),
              const SizedBox(width: 20),
              S3Knob(
                label: 'MAKEUP',
                valueText: fmtDb(s.compMake),
                frac: (s.compMake / 24).clamp(0, 1).toDouble(),
                arcColor: const Color(0xFFF26D6D),
                diameter: 84,
                onFrac: (f) =>
                    ctl.setParam('compMake', f * 24, drag: true),
                onEnd: () => ctl.setParam('compMake', s.compMake),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vMeter(String label, double frac, Color color) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1114),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: frac.clamp(0.02, 1).toDouble(),
                widthFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: S3Colors.dim, fontSize: 10.5)),
      ],
    );
  }
}

/// Grafik gate: garis transfer — di bawah ambang sinyal ditutup.
class _GatePainter extends CustomPainter {
  final double thr;
  _GatePainter({required this.thr});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(7)),
      Paint()..color = const Color(0xFF0F1114),
    );
    // sumbu -60..0 dB pada kedua sumbu
    double xOf(double db) => (db + 60) / 60 * size.width;
    double yOf(double db) => size.height - (db + 60) / 60 * size.height;
    canvas.drawLine(Offset(xOf(thr), 4), Offset(xOf(thr), size.height - 16),
        Paint()..color = const Color(0xFF2C3542)..strokeWidth = 1);
    final p = Path()
      ..moveTo(xOf(-60), yOf(-60))
      ..lineTo(xOf(thr), yOf(-60))
      ..lineTo(xOf(0), yOf(0));
    canvas.drawPath(
        p,
        Paint()
          ..color = const Color(0xFFFAAC58)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2);
    final tp = TextPainter(
      text: TextSpan(
          text: 'ambang ${fmtDb(thr)}',
          style: const TextStyle(color: S3Colors.dim, fontSize: 9.5)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(xOf(thr) + 5, 6));
  }

  @override
  bool shouldRepaint(_GatePainter old) => true;
}

/// Grafik transfer kompresor (oranye, sesuai rancangan layar 2).
class _CompPainter extends CustomPainter {
  final double thr;
  final double ratio;
  _CompPainter({required this.thr, required this.ratio});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(7)),
      Paint()..color = const Color(0xFF0F1114),
    );
    // grid
    final grid = Paint()..color = const Color(0xFF232830)..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      canvas.drawLine(Offset(size.width * i / 4, 0),
          Offset(size.width * i / 4, size.height), grid);
      canvas.drawLine(Offset(0, size.height * i / 4),
          Offset(size.width, size.height * i / 4), grid);
    }
    double xOf(double db) => (db + 60) / 60 * size.width;
    double yOf(double db) => size.height - (db + 60) / 60 * size.height;
    // garis kesatuan (referensi tipis)
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0),
        Paint()..color = const Color(0xFF2C3542)..strokeWidth = 1);
    final outAt = thr + (0 - thr) / ratio;
    final p = Path()
      ..moveTo(xOf(-60), yOf(-60))
      ..lineTo(xOf(thr), yOf(thr))
      ..lineTo(xOf(0), yOf(outAt));
    canvas.drawPath(
        p,
        Paint()
          ..color = const Color(0xFFFAAC58)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4);
    canvas.drawCircle(Offset(xOf(thr), yOf(thr)), 4.5,
        Paint()..color = const Color(0xFFFAAC58));
  }

  @override
  bool shouldRepaint(_CompPainter old) => true;
}

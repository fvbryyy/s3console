// Model keadaan alat — bentuk JSON persis /api/state firmware S3 Air (v5.2).
// Parser toleran: nilai boleh int/double/null dari JSON.

double _d(dynamic v, [double def = 0]) =>
    v == null ? def : (v as num).toDouble();
int _i(dynamic v, [int def = 0]) => v == null ? def : (v as num).toInt();

class BandState {
  bool on;
  int t; // 0 puncak, 1 low shelf, 2 high shelf
  double f, g, q;
  bool dyn;
  double dthr, drng;
  BandState({
    this.on = true,
    this.t = 0,
    this.f = 1000,
    this.g = 0,
    this.q = 1,
    this.dyn = false,
    this.dthr = -24,
    this.drng = 0,
  });
  factory BandState.fromJson(Map<String, dynamic> j) => BandState(
        on: _i(j['on'], 1) != 0,
        t: _i(j['t']),
        f: _d(j['f'], 1000),
        g: _d(j['g']),
        q: _d(j['q'], 1),
        dyn: _i(j['dyn']) != 0,
        dthr: _d(j['dthr'], -24),
        drng: _d(j['drng']),
      );
}

class DlmsChState {
  bool on;
  int src;
  bool hpfOn, lpfOn;
  double hpfF, lpfF;
  int tf;
  bool peqOn;
  List<double> peq;
  double gain, dly, lim;
  bool pol;
  DlmsChState({
    this.on = true,
    this.src = 0,
    this.hpfOn = false,
    this.hpfF = 2500,
    this.lpfOn = false,
    this.lpfF = 2500,
    this.tf = 1,
    this.peqOn = true,
    List<double>? peq,
    this.gain = 0,
    this.dly = 0,
    this.lim = -3,
    this.pol = false,
  }) : peq = peq ?? [0, 0, 0];
  factory DlmsChState.fromJson(Map<String, dynamic> j) => DlmsChState(
        on: _i(j['on'], 1) != 0,
        src: _i(j['src']),
        hpfOn: _i(j['hpfOn']) != 0,
        hpfF: _d(j['hpfF'], 2500),
        lpfOn: _i(j['lpfOn']) != 0,
        lpfF: _d(j['lpfF'], 2500),
        tf: _i(j['tf'], 1),
        peqOn: _i(j['peqOn'], 1) != 0,
        peq: (j['peq'] as List? ?? const [])
            .map((e) => _d(e))
            .toList()
            .pad3(),
        gain: _d(j['gain']),
        dly: _d(j['dly']),
        lim: _d(j['lim'], -3),
        pol: _i(j['pol']) != 0,
      );
}

extension _Pad3 on List<double> {
  List<double> pad3() =>
      length >= 3 ? sublist(0, 3) : [...this, ...List.filled(3 - length, 0.0)];
}

class DlmsState {
  bool on;
  bool inOnA, inOnB;
  double inGainA, inGainB, inDlyA, inDlyB;
  List<DlmsChState> ch;
  DlmsState({
    this.on = false,
    this.inOnA = true,
    this.inOnB = true,
    this.inGainA = 0,
    this.inGainB = 0,
    this.inDlyA = 0,
    this.inDlyB = 0,
    List<DlmsChState>? ch,
  }) : ch = ch ?? [DlmsChState(), DlmsChState(src: 1)];
  factory DlmsState.fromJson(Map<String, dynamic>? j) {
    if (j == null) return DlmsState();
    return DlmsState(
      on: _i(j['on']) != 0,
      inOnA: _i(j['inOnA'], 1) != 0,
      inOnB: _i(j['inOnB'], 1) != 0,
      inGainA: _d(j['inGainA']),
      inGainB: _d(j['inGainB']),
      inDlyA: _d(j['inDlyA']),
      inDlyB: _d(j['inDlyB']),
      ch: (j['ch'] as List? ?? const [])
          .map((e) => DlmsChState.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DspState {
  String net, fw;
  int ur, ov; // statistik underrun/overflow dari /api/state
  double preamp, trimL, trimR;
  bool polL, polR;
  bool hpfOn;
  double hpfFreq;
  int hpfSlope;
  int eqMode; // 0 PEQ, 1 GEQ
  bool bypass, loud, autoHr;
  bool gateOn;
  double gateThr, gateAtk, gateRel;
  bool compOn;
  double compThr, compRatio, compAtk, compRel, compMake;
  bool limiter;
  double ceiling;
  bool xfOn;
  double xfAmt, width, balance;
  bool mono;
  double dlyL, dlyR;
  double vol; // linear 0..1 (1 = 0 dB)
  bool mute, dim;
  double volMax;
  bool dirty, autosave;
  List<BandState> bands;
  List<double> geq;
  List<int> slots;
  DlmsState dlms;

  DspState({
    this.net = '',
    this.fw = '',
    this.ur = 0,
    this.ov = 0,
    this.preamp = 0,
    this.trimL = 0,
    this.trimR = 0,
    this.polL = false,
    this.polR = false,
    this.hpfOn = false,
    this.hpfFreq = 30,
    this.hpfSlope = 12,
    this.eqMode = 0,
    this.bypass = false,
    this.loud = false,
    this.autoHr = false,
    this.gateOn = false,
    this.gateThr = -50,
    this.gateAtk = 1,
    this.gateRel = 100,
    this.compOn = false,
    this.compThr = -18,
    this.compRatio = 2,
    this.compAtk = 10,
    this.compRel = 100,
    this.compMake = 0,
    this.limiter = true,
    this.ceiling = -1,
    this.xfOn = false,
    this.xfAmt = 0.25,
    this.width = 1,
    this.balance = 0,
    this.mono = false,
    this.dlyL = 0,
    this.dlyR = 0,
    this.vol = 0.6,
    this.mute = false,
    this.dim = false,
    this.volMax = 1,
    this.dirty = false,
    this.autosave = true,
    List<BandState>? bands,
    List<double>? geq,
    List<int>? slots,
    DlmsState? dlms,
  })  : bands = bands ?? List.generate(10, (_) => BandState()),
        geq = geq ?? List.filled(31, 0),
        slots = slots ?? List.filled(10, 0),
        dlms = dlms ?? DlmsState();

  factory DspState.fromJson(Map<String, dynamic> j) => DspState(
        net: j['net']?.toString() ?? '',
        fw: j['fw']?.toString() ?? '',
        ur: _i(j['ur']),
        ov: _i(j['ov']),
        preamp: _d(j['preamp']),
        trimL: _d(j['trimL']),
        trimR: _d(j['trimR']),
        polL: _i(j['polL']) != 0,
        polR: _i(j['polR']) != 0,
        hpfOn: _i(j['hpfOn']) != 0,
        hpfFreq: _d(j['hpfFreq'], 30),
        hpfSlope: _i(j['hpfSlope'], 12),
        eqMode: _i(j['eqMode']),
        bypass: _i(j['bypass']) != 0,
        loud: _i(j['loud']) != 0,
        autoHr: _i(j['autoHr']) != 0,
        gateOn: _i(j['gateOn']) != 0,
        gateThr: _d(j['gateThr'], -50),
        gateAtk: _d(j['gateAtk'], 1),
        gateRel: _d(j['gateRel'], 100),
        compOn: _i(j['compOn']) != 0,
        compThr: _d(j['compThr'], -18),
        compRatio: _d(j['compRatio'], 2),
        compAtk: _d(j['compAtk'], 10),
        compRel: _d(j['compRel'], 100),
        compMake: _d(j['compMake']),
        limiter: _i(j['limiter'], 1) != 0,
        ceiling: _d(j['ceiling'], -1),
        xfOn: _i(j['xfOn']) != 0,
        xfAmt: _d(j['xfAmt'], 0.25),
        width: _d(j['width'], 1),
        balance: _d(j['balance']),
        mono: _i(j['mono']) != 0,
        dlyL: _d(j['dlyL']),
        dlyR: _d(j['dlyR']),
        vol: _d(j['vol'], 0.6),
        mute: _i(j['mute']) != 0,
        dim: _i(j['dim']) != 0,
        volMax: _d(j['volMax'], 1),
        dirty: _i(j['dirty']) != 0,
        autosave: _i(j['autosave'], 1) != 0,
        bands: (j['bands'] as List? ?? const [])
            .map((e) => BandState.fromJson(e as Map<String, dynamic>))
            .toList(),
        geq: (j['geq'] as List? ?? const []).map((e) => _d(e)).toList(),
        slots: (j['slots'] as List? ?? const []).map((e) => _i(e)).toList(),
        dlms: DlmsState.fromJson(j['dlms'] as Map<String, dynamic>?),
      );
}

class MeterData {
  final double l, r, gr;
  final bool clip, dirty;
  final int flt;
  const MeterData({
    this.l = 0,
    this.r = 0,
    this.gr = 0,
    this.clip = false,
    this.dirty = false,
    this.flt = 0,
  });
  factory MeterData.fromJson(Map<String, dynamic> j) => MeterData(
        l: _d(j['l']),
        r: _d(j['r']),
        gr: _d(j['gr']),
        clip: _i(j['clip']) != 0,
        dirty: _i(j['dirty']) != 0,
        flt: _i(j['flt']),
      );
}

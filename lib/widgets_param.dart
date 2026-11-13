import 'package:flutter/material.dart';

import 'theme.dart';

/// Sistem parameter PADAT gaya konsol profesional (rombakan total atas
/// keluhan user: panel jangan cuma berisi satu kenop/blok raksasa + ruang
/// kosong). Satu baris parameter = label kecil tetap, kontrol yang meregang
/// mengisi lebar, dan kotak nilai presisi. Semua panel detail memakai
/// komponen ini agar rapat, rata, dan konsisten.

const _labelW = 96.0;
const _valueW = 88.0;

/// Baris slider parameter: [LABEL] [———●———] [kotak nilai].
class ParamSlider extends StatelessWidget {
  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final Color color;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final VoidCallback? onEnd;
  const ParamSlider({
    super.key,
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
    this.enabled = true,
    this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: _labelW,
            child: Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: enabled ? S3Colors.dim : const Color(0xFF565F6B))),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                activeTrackColor: enabled ? color : const Color(0xFF3A4048),
                inactiveTrackColor: const Color(0xFF272C34),
                thumbColor: enabled ? Colors.white : S3Colors.dim,
                overlayColor: color.withValues(alpha: 0.16),
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 9),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: value.clamp(min, max).toDouble(),
                min: min,
                max: max,
                onChanged: enabled ? onChanged : null,
                onChangeEnd: onEnd == null ? null : (_) => onEnd!(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: _valueW,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF101216),
              border: Border.all(color: S3Colors.line),
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.center,
            child: Text(valueText,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: enabled
                        ? const Color(0xFF6ED0E4)
                        : S3Colors.dim)),
          ),
        ],
      ),
    );
  }
}

/// Baris pilihan tersegmentasi: [LABEL] [pil1|pil2|...] mengisi lebar.
/// Pilihan aktif = blok biru terangkat menyala; nonaktif = kartu redup.
class ParamSegmented extends StatelessWidget {
  final String label;
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;
  final double height;
  const ParamSegmented({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.height = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: _labelW,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: S3Colors.dim)),
          ),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < options.length; i++)
                  Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.only(right: i < options.length - 1 ? 6 : 0),
                      child: Material(
                        color: selected == i ? S3Colors.blue : S3Colors.card,
                        elevation: selected == i ? 5 : 1.5,
                        shadowColor:
                            selected == i ? S3Colors.blue : Colors.black,
                        borderRadius: BorderRadius.circular(6),
                        child: InkWell(
                          onTap: () => onSelect(i),
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: height,
                            child: Center(
                              child: Text(options[i],
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: selected == i
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
          ),
        ],
      ),
    );
  }
}

/// Baris info baca-saja (ringkasan keadaan) — pengisi panel yang berisi data
/// nyata, bukan kontrol.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF262B33))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _labelW,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: S3Colors.dim)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Judul seksi kecil di dalam panel.
class SectionHead extends StatelessWidget {
  final String text;
  const SectionHead(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: S3Colors.dim)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/configure_download_provider.dart';

class NumericalInputRow extends StatefulWidget {
  const NumericalInputRow({
    super.key,
    required this.label,
    required this.suffixText,
    required this.value,
    required this.min,
    required this.max,
    this.maxEligibleTilesPreview,
    required this.onChanged,
  });

  final String label;
  final String suffixText;
  final int Function(ConfigureDownloadProvider provider) value;
  final int min;
  final int? max;
  final int? maxEligibleTilesPreview;
  final void Function(ConfigureDownloadProvider provider, int value) onChanged;

  @override
  State<NumericalInputRow> createState() => _NumericalInputRowState();
}

class _NumericalInputRowState extends State<NumericalInputRow> {
  TextEditingController? tec;

  @override
  Widget build(BuildContext context) =>
      Selector<ConfigureDownloadProvider, int>(
        selector: (context, provider) => widget.value(provider),
        builder: (context, currentValue, _) {
          tec ??= TextEditingController(text: currentValue.toString());

          return Row(
            children: [
              Text(widget.label),
              const Spacer(),
              if (widget.maxEligibleTilesPreview != null) ...[
                IconButton(
                  icon: const Icon(Icons.visibility),
                  disabledColor: Colors.green,
                  tooltip: currentValue > widget.maxEligibleTilesPreview!
                      ? 'Tap to enable following download live'
                      : 'Eligible to follow download live',
                  onPressed: currentValue > widget.maxEligibleTilesPreview!
                      ? () {
                          widget.onChanged(
                            context.read<ConfigureDownloadProvider>(),
                            widget.maxEligibleTilesPreview!,
                          );
                          tec!.text = widget.maxEligibleTilesPreview.toString();
                        }
                      : null,
                ),
                const SizedBox(width: 8),
              ],
              if (widget.max != null) ...[
                Tooltip(
                  message: currentValue == widget.max
                      ? 'Limited in the example app'
                      : '',
                  child: Icon(
                    Icons.lock,
                    color: currentValue == widget.max
                        ? Colors.amber
                        : Colors.white.withOpacity(0.2),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              IntrinsicWidth(
                child: TextFormField(
                  controller: tec,
                  textAlign: TextAlign.end,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    isDense: true,
                    counterText: '',
                    suffixText: ' ${widget.suffixText}',
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    _NumericalRangeFormatter(
                      min: widget.min,
                      max: widget.max ?? 9223372036854775807,
                    ),
                  ],
                  onChanged: (newVal) => widget.onChanged(
                    context.read<ConfigureDownloadProvider>(),
                    int.tryParse(newVal) ?? currentValue,
                  ),
                ),
              ),
            ],
          );
        },
      );
}

class _NumericalRangeFormatter extends TextInputFormatter {
  const _NumericalRangeFormatter({required this.min, required this.max});
  final int min;
  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final int parsed = int.parse(newValue.text);

    if (parsed < min) {
      return TextEditingValue.empty.copyWith(
        text: min.toString(),
        selection: TextSelection.collapsed(offset: min.toString().length),
      );
    }
    if (parsed > max) {
      return TextEditingValue.empty.copyWith(
        text: max.toString(),
        selection: TextSelection.collapsed(offset: max.toString().length),
      );
    }

    return newValue;
  }
}

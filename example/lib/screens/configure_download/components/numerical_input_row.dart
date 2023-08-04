import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/configure_download_provider.dart';

class NumericalInputRow extends StatelessWidget {
  const NumericalInputRow({
    super.key,
    required this.label,
    required this.suffixText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String suffixText;
  final int Function(ConfigureDownloadProvider provider) value;
  final int min;
  final int max;
  final void Function(ConfigureDownloadProvider provider, int value) onChanged;

  @override
  Widget build(BuildContext context) {
    final currentValue = context.select<ConfigureDownloadProvider, int>(value);

    return Row(
      children: [
        Text(label),
        const Spacer(),
        Icon(
          Icons.lock,
          color: currentValue == max
              ? Colors.amber
              : Colors.white.withOpacity(0.2),
        ),
        const SizedBox(width: 16),
        IntrinsicWidth(
          child: TextFormField(
            initialValue: currentValue.toString(),
            textAlign: TextAlign.end,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              isDense: true,
              counterText: '',
              suffixText: ' $suffixText',
            ),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              _NumericalRangeFormatter(min: min, max: max),
            ],
            onChanged: (newVal) => onChanged(
              context.read<ConfigureDownloadProvider>(),
              int.tryParse(newVal) ?? currentValue,
            ),
          ),
        ),
      ],
    );
  }
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

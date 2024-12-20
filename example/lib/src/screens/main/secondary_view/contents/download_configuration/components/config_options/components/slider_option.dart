part of '../config_options.dart';

class _SliderOption extends StatelessWidget {
  const _SliderOption({
    required this.icon,
    required this.tooltipMessage,
    required this.descriptor,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final Icon icon;
  final String tooltipMessage;
  final String descriptor;
  final int value;
  final int min;
  final int max;
  final void Function(int value) onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Tooltip(message: tooltipMessage, child: icon),
          const SizedBox(width: 6),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: (r) => onChanged(r.toInt()),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              '$value $descriptor',
              textAlign: TextAlign.end,
            ),
          ),
        ],
      );
}

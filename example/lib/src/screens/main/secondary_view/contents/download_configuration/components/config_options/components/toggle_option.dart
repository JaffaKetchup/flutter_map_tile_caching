part of '../config_options.dart';

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final Icon icon;
  final String title;
  final String description;
  final bool value;
  // ignore: avoid_positional_boolean_parameters
  final void Function(bool value) onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(
                  description,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      );
}

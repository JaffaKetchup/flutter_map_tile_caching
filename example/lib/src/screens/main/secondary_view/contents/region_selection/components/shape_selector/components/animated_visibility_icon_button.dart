part of '../shape_selector.dart';

class _AnimatedVisibilityIconButton extends StatelessWidget {
  const _AnimatedVisibilityIconButton.outlined({
    required this.icon,
    this.onPressed,
    this.tooltip,
    required this.isVisible,
    // ignore: avoid_field_initializers_in_const_classes
  }) : _mode = 0;

  const _AnimatedVisibilityIconButton.filledTonal({
    required this.icon,
    this.onPressed,
    this.tooltip,
    required this.isVisible,
    // ignore: avoid_field_initializers_in_const_classes
  }) : _mode = 1;

  const _AnimatedVisibilityIconButton.filled({
    required this.icon,
    this.onPressed,
    this.tooltip,
    required this.isVisible,
    // ignore: avoid_field_initializers_in_const_classes
  }) : _mode = 2;

  final Icon icon;
  final void Function()? onPressed;
  final String? tooltip;
  final bool isVisible;

  final int _mode;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        height: isVisible ? 40 : 0,
        width: isVisible ? 48 : 0,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: switch (_mode) {
            0 => IconButton.outlined(
                onPressed: onPressed,
                icon: FittedBox(child: icon),
                tooltip: tooltip,
              ),
            1 => IconButton.filledTonal(
                onPressed: onPressed,
                icon: FittedBox(child: icon),
                tooltip: tooltip,
              ),
            2 => IconButton.filled(
                onPressed: onPressed,
                icon: FittedBox(child: icon),
                tooltip: tooltip,
              ),
            _ => throw UnsupportedError('Unreachable.'),
          },
        ),
      );
}

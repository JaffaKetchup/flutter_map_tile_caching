import 'package:flutter/material.dart';

class SideViewPanel extends StatelessWidget {
  const SideViewPanel({
    super.key,
    required this.child,
    this.autoPadding = true,
  });

  final Widget child;
  final bool autoPadding;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
        ),
        padding: autoPadding ? const EdgeInsets.all(16) : null,
        width: double.infinity,
        child: child,
      );
}

import 'package:flutter/material.dart';

class SideViewPanel extends StatelessWidget {
  const SideViewPanel({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
        ),
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        child: child,
      );
}

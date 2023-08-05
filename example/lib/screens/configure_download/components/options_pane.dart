import 'package:flutter/material.dart';

import '../../../shared/misc/exts/interleave.dart';

class OptionsPane extends StatelessWidget {
  const OptionsPane({
    super.key,
    required this.label,
    required this.children,
    this.interPadding = 8,
  });

  final String label;
  final Iterable<Widget> children;
  final double interPadding;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(label),
          ),
          const SizedBox.square(dimension: 4),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: children.singleOrNull ??
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children
                        .interleave(SizedBox.square(dimension: interPadding))
                        .toList(),
                  ),
            ),
          ),
        ],
      );
}

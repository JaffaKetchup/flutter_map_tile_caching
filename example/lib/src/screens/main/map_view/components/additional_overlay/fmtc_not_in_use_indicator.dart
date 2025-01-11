import 'package:flutter/material.dart';

import '../../map_view.dart';

class FMTCNotInUseIndicator extends StatelessWidget {
  const FMTCNotInUseIndicator({
    super.key,
    required this.mode,
  });

  final MapViewMode mode;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => IgnorePointer(
          child: Opacity(
            opacity: 2 / 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(255 ~/ 2),
                    spreadRadius: 6,
                    blurRadius: 8,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hide_image),
                    if (constraints.maxWidth > 320) ...[
                      const SizedBox(width: 8),
                      const Text('FMTC not in use in this view'),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

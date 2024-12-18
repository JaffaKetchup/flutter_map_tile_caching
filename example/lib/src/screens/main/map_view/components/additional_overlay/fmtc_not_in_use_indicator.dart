import 'package:flutter/material.dart';

import '../../map_view.dart';

class FMTCNotInUseIndicator extends StatelessWidget {
  const FMTCNotInUseIndicator({
    super.key,
    required this.mode,
  });

  final MapViewMode mode;

  @override
  Widget build(BuildContext context) => IgnorePointer(
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hide_image),
                SizedBox(width: 8),
                Text('FMTC not in use in this view'),
              ],
            ),
          ),
        ),
      );
}

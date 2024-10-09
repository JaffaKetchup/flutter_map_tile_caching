import 'package:flutter/material.dart';

class StatDisplay extends StatelessWidget {
  const StatDisplay({
    super.key,
    required this.statistic,
    required this.description,
  });

  final String statistic;
  final String description;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: Column(
          children: [
            Text(
              statistic,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              description,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

import 'package:flutter/material.dart';

class StatDisplay extends StatelessWidget {
  const StatDisplay({
    Key? key,
    required this.statistic,
    required this.description,
  }) : super(key: key);

  final String statistic;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            statistic,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            description,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      );
}

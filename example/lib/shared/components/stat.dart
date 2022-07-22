import 'package:flutter/material.dart';

class Stat extends StatelessWidget {
  const Stat({
    Key? key,
    required this.statistic,
    required this.description,
  }) : super(key: key);

  final String? statistic;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          statistic == null
              ? const CircularProgressIndicator()
              : Text(
                  statistic!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      );
}

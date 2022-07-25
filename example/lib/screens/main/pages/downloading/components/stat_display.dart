import 'package:flutter/material.dart';

class StatDisplay extends StatelessWidget {
  const StatDisplay({
    Key? key,
    required this.largeText,
    required this.smallText,
  }) : super(key: key);

  final String largeText;
  final String smallText;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            largeText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            smallText,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      );
}

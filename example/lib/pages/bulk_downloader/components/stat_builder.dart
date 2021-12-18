import 'package:flutter/material.dart';

Column statBuilder({
  required String stat,
  required String description,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        stat,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        description,
        style: const TextStyle(
          fontSize: 18,
        ),
      ),
    ],
  );
}

import 'package:flutter/material.dart';

class NoPathSelected extends StatelessWidget {
  const NoPathSelected({super.key});

  @override
  Widget build(BuildContext context) => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.keyboard_rounded, size: 48),
          Text(
            'To get started, input/select a path to a file',
            style: TextStyle(fontSize: 15),
          ),
        ],
      );
}

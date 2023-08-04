import 'package:flutter/material.dart';

class SectionSeparator extends StatelessWidget {
  const SectionSeparator({super.key});

  @override
  Widget build(BuildContext context) => const Column(
        children: [
          SizedBox(height: 5),
          Divider(),
          SizedBox(height: 5),
        ],
      );
}

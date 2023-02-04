import 'package:flutter/material.dart';

class SectionSeparator extends StatelessWidget {
  const SectionSeparator({super.key});

  @override
  Widget build(BuildContext context) => Column(
        children: const [
          SizedBox(height: 5),
          Divider(),
          SizedBox(height: 5),
        ],
      );
}

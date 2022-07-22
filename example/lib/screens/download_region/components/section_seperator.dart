import 'package:flutter/material.dart';

class SectionSeperator extends StatelessWidget {
  const SectionSeperator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Column(
        children: const [
          SizedBox(height: 5),
          Divider(),
          SizedBox(height: 5),
        ],
      );
}

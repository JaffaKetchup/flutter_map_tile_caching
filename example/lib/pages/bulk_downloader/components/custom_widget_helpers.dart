import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

Row buildTextDivider(Text text) {
  return Row(
    children: [
      const SizedBox(
        child: Divider(thickness: 1, height: 40),
        width: 30,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: text,
      ),
      const Expanded(child: Divider(thickness: 1, height: 40)),
    ],
  );
}

Row buildNumberSelector({
  required int value,
  required int min,
  required int max,
  required void Function(int) onChanged,
  required IconData icon,
}) {
  return Row(
    children: [
      const Spacer(),
      Icon(icon),
      const Spacer(),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black54),
        ),
        child: NumberPicker(
          value: value,
          minValue: min,
          maxValue: max,
          onChanged: onChanged,
          axis: Axis.horizontal,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.black54),
          ),
          haptics: true,
        ),
      ),
    ],
  );
}

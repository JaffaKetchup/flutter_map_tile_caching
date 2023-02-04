import 'package:flutter/material.dart';

class Crosshairs extends StatelessWidget {
  const Crosshairs({
    super.key,
    this.size = 20,
    this.thickness = 2,
  });

  final double size;
  final double thickness;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: thickness,
            height: size,
            color: Colors.black,
          ),
          Container(
            width: size,
            height: thickness,
            color: Colors.black,
          ),
        ],
      );
}

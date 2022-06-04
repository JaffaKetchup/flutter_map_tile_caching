import 'package:flutter/material.dart';

class Crosshairs extends StatelessWidget {
  const Crosshairs({
    Key? key,
    this.length = 20,
    this.thickness = 2,
  }) : super(key: key);

  final double length;
  final double thickness;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: thickness,
            height: length,
            color: Colors.black,
          ),
          Container(
            width: length,
            height: thickness,
            color: Colors.black,
          ),
        ],
      );
}

import 'package:flutter/material.dart';

class PanelView extends StatelessWidget {
  const PanelView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.blueGrey,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text('safffffffffffffffffffffffffffffe'),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../state/general_provider.dart';

class PanelView extends StatelessWidget {
  const PanelView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GeneralProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          child: Container(
            color: Colors.blueGrey,
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text('Placeholder: Expanded'),
            ),
          ),
        );
      },
    );
  }
}

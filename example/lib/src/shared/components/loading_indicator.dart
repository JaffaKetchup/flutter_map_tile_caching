import 'package:flutter/material.dart';

class SharedLoadingIndicator extends StatelessWidget {
  const SharedLoadingIndicator(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator.adaptive(),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            const Text(
              'This should only take a few moments',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
}

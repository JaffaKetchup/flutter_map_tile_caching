import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    Key? key,
    this.message = 'Please Wait...',
  }) : super(key: key);

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

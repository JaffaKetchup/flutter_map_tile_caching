import 'package:flutter/material.dart';

Widget loadingScreen(BuildContext context, String extraInfo) {
  return SizedBox(
    width: MediaQuery.of(context).size.width,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator.adaptive(),
        const SizedBox(height: 20),
        Text(
          'Loading...\n$extraInfo',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

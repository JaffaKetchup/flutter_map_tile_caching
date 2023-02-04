import 'package:flutter/material.dart';

class UpToDate extends StatelessWidget {
  const UpToDate({
    super.key,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.done,
              size: 38,
            ),
            SizedBox(height: 10),
            Text(
              'Up To Date',
              textAlign: TextAlign.center,
            ),
            Text(
              "with the latest example app from the 'main' branch",
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
}

import 'package:flutter/material.dart';

class FailedToCheck extends StatelessWidget {
  const FailedToCheck({
    super.key,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.error,
              size: 38,
              color: Colors.red,
            ),
            SizedBox(height: 10),
            Text(
              'Failed To Check For Updates\nThe remote URL could not be reached',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

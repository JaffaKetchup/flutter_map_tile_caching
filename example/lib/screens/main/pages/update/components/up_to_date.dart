import 'package:flutter/material.dart';

class UpToDate extends StatelessWidget {
  const UpToDate({
    Key? key,
  }) : super(key: key);

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
          ],
        ),
      );
}

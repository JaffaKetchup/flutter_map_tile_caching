import 'package:flutter/material.dart';

class EmptyIndicator extends StatelessWidget {
  const EmptyIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done, size: 38),
            SizedBox(height: 10),
            Text('No Recoverable Regions Found'),
          ],
        ),
      );
}

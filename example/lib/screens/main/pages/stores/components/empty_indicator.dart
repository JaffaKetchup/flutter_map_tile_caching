import 'package:flutter/material.dart';

class EmptyIndicator extends StatelessWidget {
  const EmptyIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.folder_off, size: 36),
            SizedBox(height: 10),
            Text('No Stores Found'),
          ],
        ),
      );
}

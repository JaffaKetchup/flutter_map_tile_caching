import 'package:flutter/material.dart';

class ImportCompleteStage extends StatelessWidget {
  const ImportCompleteStage({
    super.key,
    required this.tiles,
    required this.duration,
  });

  final int tiles;
  final Duration duration;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: Colors.green,
              ),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.done_all, size: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Successfully imported $tiles tiles in $duration!',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Exit',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
}

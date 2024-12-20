import 'package:flutter/material.dart';

class ImportErrorStage extends StatelessWidget {
  const ImportErrorStage({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, size: 48),
            const SizedBox(height: 6),
            Text(
              "Whoops, looks like we couldn't handle that file",
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              "Ensure you selected the correct file, that it hasn't "
              'been modified, and that it was exported from the same '
              'version of FMTC.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SelectableText(
              'Type: ${error.runtimeType}',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SelectableText(
              'Error: $error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
}

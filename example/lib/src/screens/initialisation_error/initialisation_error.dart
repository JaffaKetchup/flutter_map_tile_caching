import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../main.dart';

class InitialisationError extends StatelessWidget {
  const InitialisationError({super.key, required this.err});

  final Object? err;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48),
                const SizedBox(height: 6),
                Text(
                  'Whoops, look like FMTC ran into an error initialising',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'We recommend trying to delete the existing root, as it may '
                  'have become corrupt.\nPlease be aware that this will delete '
                  'any cached data, and will cause the app to restart.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SelectableText(
                  'Type: ${err.runtimeType}',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                SelectableText(
                  'Error: $err',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () async {
                    void showFailure() {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Unfortuately, that didn't work. Try clearing "
                              "the app's storage and cache manually.",
                            ),
                          ),
                        );
                      }
                    }

                    final dir = Directory(
                      path.join(
                        (await getApplicationDocumentsDirectory())
                            .absolute
                            .path,
                        'fmtc',
                      ),
                    );

                    if (!await dir.exists()) {
                      showFailure();
                      return;
                    }

                    try {
                      await dir.delete(recursive: true);
                    } on FileSystemException {
                      showFailure();
                      rethrow;
                    }

                    runApp(const SizedBox.shrink()); // Destroy current app
                    main(); // Re-run app
                  },
                  child: const Text(
                    'Reset FMTC & attempt re-initialisation',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../main.dart';

class InitialisationError extends StatelessWidget {
  const InitialisationError({super.key, required this.err});

  final Object? err;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64),
                const SizedBox(height: 12),
                Text(
                  'Whoops, look like FMTC ran into an error initialising',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall!
                      .copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SelectableText(
                  'Type: ${err.runtimeType}',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                SelectableText(
                  'Error: $err',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Text(
                  'We recommend trying to delete the existing root, as it may '
                  'have become corrupt.\nPlease be aware that this will delete '
                  'any cached data, and will cause the app to restart.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
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

                    runApp(const SizedBox.shrink());

                    main();
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

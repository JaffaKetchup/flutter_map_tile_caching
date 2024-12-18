import 'package:flutter/material.dart';

class NoRegions extends StatelessWidget {
  const NoRegions({super.key});

  @override
  Widget build(BuildContext context) => SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_fix_off, size: 42),
                const SizedBox(height: 12),
                Text(
                  'No failed downloads',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  "If a download fails unexpectedly, it'll appear here! You can "
                  'then finish the end of the download.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
}

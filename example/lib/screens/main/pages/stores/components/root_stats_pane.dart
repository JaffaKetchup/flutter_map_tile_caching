import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../../../../shared/components/loading_indicator.dart';
import '../../../../../shared/misc/exts/size_formatter.dart';
import '../components/stat_display.dart';

class RootStatsPane extends StatefulWidget {
  const RootStatsPane({super.key});

  @override
  State<RootStatsPane> createState() => _RootStatsPaneState();
}

class _RootStatsPaneState extends State<RootStatsPane> {
  late final watchStream = FMTCRoot.stats.watchStores(
    triggerImmediately: true,
  );

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSecondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: StreamBuilder(
          stream: watchStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: LoadingIndicator('Retrieving Stores'),
              );
            }

            return Wrap(
              alignment: WrapAlignment.spaceEvenly,
              runAlignment: WrapAlignment.spaceEvenly,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 20,
              children: [
                FutureBuilder(
                  future: FMTCRoot.stats.length,
                  builder: (context, snapshot) => StatDisplay(
                    statistic: snapshot.data?.toString(),
                    description: 'total tiles',
                  ),
                ),
                FutureBuilder(
                  future: FMTCRoot.stats.size,
                  builder: (context, snapshot) => StatDisplay(
                    statistic: snapshot.data == null
                        ? null
                        : ((snapshot.data! * 1024).asReadableSize),
                    description: 'total tiles size',
                  ),
                ),
                FutureBuilder(
                  future: FMTCRoot.stats.realSize,
                  builder: (context, snapshot) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatDisplay(
                        statistic: snapshot.data == null
                            ? null
                            : ((snapshot.data! * 1024).asReadableSize),
                        description: 'database size',
                      ),
                      const SizedBox.square(dimension: 6),
                      IconButton(
                        icon: const Icon(Icons.help_outline),
                        onPressed: () => _showDatabaseSizeInfoDialog(context),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

  void _showDatabaseSizeInfoDialog(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Database Size'),
        content: const Text(
          'This measurement refers to the actual size of the database root '
          '(which may be a flat/file or another structure).\nIncludes database '
          'overheads, and may not follow the total tiles size in a linear '
          'relationship, or any relationship at all.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

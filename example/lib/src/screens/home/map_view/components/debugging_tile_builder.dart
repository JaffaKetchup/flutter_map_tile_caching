import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class DebuggingTileBuilder extends StatelessWidget {
  const DebuggingTileBuilder({
    super.key,
    required this.tileWidget,
    required this.tile,
    required this.tileLoadingDebugger,
    required this.usingFMTC,
  });

  final Widget tileWidget;
  final TileImage tile;
  final ValueNotifier<TileLoadingInterceptorMap> tileLoadingDebugger;
  final bool usingFMTC;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black.withOpacity(0.8),
                width: 3,
              ),
              color: Colors.white.withOpacity(0.5),
            ),
            position: DecorationPosition.foreground,
            child: tileWidget,
          ),
          if (!usingFMTC)
            const OverflowBox(
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.disabled_by_default_rounded,
                      size: 32,
                    ),
                    SizedBox(height: 6),
                    Text('FMTC not in use'),
                  ],
                ),
              ),
            )
          else
            ValueListenableBuilder(
              valueListenable: tileLoadingDebugger,
              builder: (context, value, _) {
                final info = value[tile.coordinates];

                if (info == null) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'x${tile.coordinates.x} y${tile.coordinates.y} '
                          'z${tile.coordinates.z}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        if (info.error case final error?)
                          Text(
                            error is FMTCBrowsingError
                                ? '`${error.type.name}`'
                                : 'Unknown error (${error.runtimeType})',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        if (info.resultPath case final result?) ...[
                          Text(
                            '`${result.name}` in ${tile.loadFinishedAt == null || tile.loadStarted == null ? '...' : tile.loadFinishedAt!.difference(tile.loadStarted!).inMilliseconds} ms',
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '(${info.cacheFetchDuration.inMilliseconds} ms cache${info.networkFetchDuration == null ? ')' : ' | ${info.networkFetchDuration!.inMilliseconds} ms network)'}\n',
                            textAlign: TextAlign.center,
                          ),
                          if (info.existingStores case final existingStores?)
                            Text(
                              "Existed in: '${existingStores.join("', '")}'",
                              textAlign: TextAlign.center,
                            )
                          else
                            const Text(
                              'New tile',
                              textAlign: TextAlign.center,
                            ),
                          if (info.storesWriteResult case final writeResult?)
                            FutureBuilder(
                              future: writeResult,
                              builder: (context, snapshot) {
                                if (snapshot.data == null) {
                                  return const Text('Caching tile...');
                                }
                                return TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          _TileWriteResultsDialog(
                                        results: snapshot.data!,
                                      ),
                                    );
                                  },
                                  child: const Text('View write result'),
                                );
                              },
                            )
                          else
                            const Text('No write necessary'),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      );
}

class _TileWriteResultsDialog extends StatelessWidget {
  const _TileWriteResultsDialog({required this.results});

  final Map<String, bool> results;

  @override
  Widget build(BuildContext context) {
    final newlyWritten =
        results.entries.where((e) => e.value).map((e) => e.key);
    final updated = results.entries.where((e) => !e.value).map((e) => e.key);

    return AlertDialog.adaptive(
      title: const Text('Tile Write Results'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Newly written to: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(newlyWritten.isEmpty ? 'None' : newlyWritten.join('\n')),
          const Text(
            '\nUpdated in: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(updated.isEmpty ? 'None' : updated.join('\n')),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

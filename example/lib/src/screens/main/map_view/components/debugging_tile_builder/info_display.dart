part of 'debugging_tile_builder.dart';

class _ResultDisplay extends StatelessWidget {
  const _ResultDisplay({
    required this.tile,
    required this.fmtcResult,
  });

  final TileImage tile;
  final TileLoadingInterceptorResult fmtcResult;

  @override
  Widget build(BuildContext context) => Padding(
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
              if (fmtcResult.error?.error case final error?)
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
              if (fmtcResult.resultPath case final result?) ...[
                Text(
                  '''`${result.name}` in ${tile.loadFinishedAt == null || tile.loadStarted == null ? '...' : tile.loadFinishedAt!.difference(tile.loadStarted!).inMilliseconds} ms''',
                  textAlign: TextAlign.center,
                ),
                Text(
                  '''(${fmtcResult.cacheFetchDuration.inMilliseconds} ms cache${fmtcResult.networkFetchDuration == null ? ')' : ' | ${fmtcResult.networkFetchDuration!.inMilliseconds} ms network)'}\n''',
                  textAlign: TextAlign.center,
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (fmtcResult.existingStores == null) return;
                        showDialog(
                          context: context,
                          builder: (context) => _TileReadResultsDialog(
                            results: fmtcResult.existingStores!,
                            trfosaf: fmtcResult
                                .tileRetrievedFromOtherStoresAsFallback,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: fmtcResult.existingStores != null
                            ? const Icon(Icons.visibility)
                            : const Icon(Icons.visibility_off),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FutureBuilder(
                      future: fmtcResult.storesWriteResult,
                      builder: (context, snapshot) => GestureDetector(
                        onTap: () {
                          if (snapshot.data == null) return;
                          showDialog(
                            context: context,
                            builder: (context) => _TileWriteResultsDialog(
                              results: snapshot.data!,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: snapshot.data != null
                              ? const Icon(Icons.edit)
                              : const Icon(Icons.edit_off),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
}

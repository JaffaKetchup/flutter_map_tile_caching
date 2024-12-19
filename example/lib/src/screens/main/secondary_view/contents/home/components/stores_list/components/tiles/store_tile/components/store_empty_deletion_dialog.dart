import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../../../../../../../../shared/state/download_provider.dart';

class StoreEmptyDeletionDialog extends StatefulWidget {
  const StoreEmptyDeletionDialog({
    super.key,
    required this.storeName,
  });

  final String storeName;

  @override
  State<StoreEmptyDeletionDialog> createState() =>
      _StoreEmptyDeletionDialogState();
}

class _StoreEmptyDeletionDialogState extends State<StoreEmptyDeletionDialog> {
  late final _recoveryRegions = FMTCRoot.recovery.recoverableRegions.then(
    (regions) => regions.failedOnly
        .where((region) => region.storeName == widget.storeName)
        .map((region) => region.id),
  );
  late final _tilesCount = FMTCStore(widget.storeName).stats.length;
  late final _combinedFutures = (_recoveryRegions, _tilesCount).wait;

  late final _isDownloading =
      context.read<DownloadingProvider>().storeName == widget.storeName;

  @override
  Widget build(BuildContext context) => AlertDialog.adaptive(
        icon: const Icon(Icons.delete_forever),
        title: Text(
          'Empty/delete ${widget.storeName}?',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder(
              future: _combinedFutures,
              builder: (context, snapshot) {
                if ((snapshot.data?.$1.length ?? 0) == 0) {
                  return const SizedBox.shrink();
                }

                return Text(
                  'Deleting this store will also delete '
                  '${snapshot.requireData.$1.length} associated recoverable '
                  'region(s).',
                  textAlign: TextAlign.center,
                );
              },
            ),
            const Text(
              'Emptying or deleting a store cannot be undone.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            height: 40,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          SizedBox(
            height: 40,
            child: FutureBuilder(
              future: _combinedFutures,
              builder: (context, snapshot) {
                if (snapshot.data == null) return const SizedBox.shrink();
                if (snapshot.requireData.$2 == 0) {
                  return const FilledButton.tonal(
                    onPressed: null,
                    child: Text('Empty'),
                  );
                }
                return FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(
                    (
                      isDeleting: false,
                      future: FMTCStore(widget.storeName).manage.reset(),
                    ),
                  ),
                  child: Text('Empty ${snapshot.requireData.$2} tiles'),
                );
              },
            ),
          ),
          SizedBox(
            height: 40,
            child: FutureBuilder(
              future: _combinedFutures,
              builder: (context, snapshot) {
                if (snapshot.data == null) {
                  return const UnconstrainedBox(
                    child: SizedBox.square(
                      dimension: 30,
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  );
                }

                final button = FilledButton(
                  onPressed: _isDownloading
                      ? null
                      : () => Navigator.of(context).pop(
                            (
                              isDeleting: true,
                              future: Future.wait(
                                [
                                  FMTCStore(widget.storeName).manage.delete(),
                                  ...snapshot.requireData.$1.map(
                                    (id) => FMTCRoot.recovery.cancel(id),
                                  ),
                                ],
                              )
                            ),
                          ),
                  child: const Text('Delete'),
                );

                if (!_isDownloading) return button;

                return Tooltip(
                  message:
                      'Cannot delete store whilst a\ndownload is in progress',
                  textAlign: TextAlign.center,
                  child: button,
                );
              },
            ),
          ),
        ],
      );
}

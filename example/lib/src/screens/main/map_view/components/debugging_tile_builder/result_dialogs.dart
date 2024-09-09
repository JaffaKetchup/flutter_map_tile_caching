part of 'debugging_tile_builder.dart';

class _TileReadResultsDialog extends StatelessWidget {
  const _TileReadResultsDialog({
    required this.results,
    required this.trfosaf,
  });

  final List<String> results;
  final bool trfosaf;

  @override
  Widget build(BuildContext context) => AlertDialog.adaptive(
        title: const Text('Tile Cache Exists Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exists in:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(results.join('\n')),
            Text(
              '\nThis does not imply that the tile was actually used/retrieved '
              'from these stores.\n'
              '`tileRetrievedFromOtherStoresAsFallback`: $trfosaf',
            ),
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

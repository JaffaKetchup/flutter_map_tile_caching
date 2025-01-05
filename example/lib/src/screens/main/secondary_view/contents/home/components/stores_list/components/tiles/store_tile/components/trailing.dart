part of '../store_tile.dart';

class _Trailing extends StatelessWidget {
  const _Trailing({
    required this.storeName,
    required this.matchesUrl,
    required this.useCompactLayout,
  });

  final String storeName;
  final bool matchesUrl;
  final bool useCompactLayout;

  @override
  Widget build(BuildContext context) {
    final urlMismatch = AnimatedOpacity(
      opacity: matchesUrl ? 0 : 1,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: IgnorePointer(
        ignoring: matchesUrl,
        child: SizedBox.expand(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.error.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(
                  Icons.link_off,
                  color: Colors.white,
                ),
                Text(
                  'URL mismatch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: BrowseStoreStrategySelector(
                    storeName: storeName,
                    enabled: matchesUrl,
                    useCompactLayout: useCompactLayout,
                  ),
                ),
              ),
              urlMismatch,
            ],
          ),
        ),
      ),
    );
  }
}

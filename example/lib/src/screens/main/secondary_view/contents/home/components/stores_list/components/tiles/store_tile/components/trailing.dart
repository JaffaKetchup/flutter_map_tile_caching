part of '../store_tile.dart';

class _Trailing extends StatelessWidget {
  const _Trailing({
    required this.storeName,
    required this.matchesUrl,
    required this.isToolsVisible,
    required this.isDeleting,
    required this.useCompactLayout,
    required this.toolsChildren,
  });

  final String storeName;
  final bool matchesUrl;
  final bool isToolsVisible;
  final bool isDeleting;
  final bool useCompactLayout;
  final List<Widget> toolsChildren;

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

    final tools = AnimatedOpacity(
      opacity: isToolsVisible ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: IgnorePointer(
        ignoring: !isToolsVisible,
        child: SizedBox.expand(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              child: isDeleting
                  ? const Center(
                      child: SizedBox.square(
                        dimension: 25,
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: toolsChildren,
                    ),
            ),
          ),
        ),
      ),
    );

    final exportCheckbox = Selector<ExportSelectionProvider, List<String>>(
      selector: (context, provider) => provider.selectedStores,
      builder: (context, selectedStores, _) => AnimatedOpacity(
        opacity: selectedStores.isNotEmpty ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: IgnorePointer(
          ignoring: selectedStores.isEmpty,
          child: SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceDim,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.note_add),
                    const SizedBox(width: 12),
                    Checkbox.adaptive(
                      value: selectedStores.contains(storeName),
                      onChanged: (v) {
                        if (v!) {
                          context
                              .read<ExportSelectionProvider>()
                              .addSelectedStore(storeName);
                        } else if (!v) {
                          context
                              .read<ExportSelectionProvider>()
                              .removeSelectedStore(storeName);
                        }
                      },
                    ),
                  ],
                ),
              ),
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
              tools,
              exportCheckbox,
            ],
          ),
        ),
      ),
    );
  }
}

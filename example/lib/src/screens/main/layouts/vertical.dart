part of '../main.dart';

class _VerticalLayout extends StatelessWidget {
  const _VerticalLayout({
    required DraggableScrollableController bottomSheetOuterController,
    required this.mapMode,
    required this.selectedTab,
    required this.constrainedHeight,
  }) : _bottomSheetOuterController = bottomSheetOuterController;

  final DraggableScrollableController _bottomSheetOuterController;
  final MapViewMode mapMode;
  final int selectedTab;
  final double constrainedHeight;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: BottomSheetMapWrapper(
          bottomSheetOuterController: _bottomSheetOuterController,
          mode: mapMode,
          layoutDirection: Axis.vertical,
        ),
        bottomSheet: SecondaryViewBottomSheet(
          selectedTab: selectedTab,
          controller: _bottomSheetOuterController,
        ),
        floatingActionButton: selectedTab == 1 &&
                context.select<RegionSelectionProvider, bool>(
                  (provider) =>
                      provider.constructedRegions.isNotEmpty &&
                      !provider.isDownloadSetupPanelVisible,
                )
            ? DelayedControllerAttachmentBuilder(
                listenable: _bottomSheetOuterController,
                builder: (context, _) {
                  final pixels = _bottomSheetOuterController.isAttached
                      ? _bottomSheetOuterController.pixels
                      : 0;
                  return FloatingActionButton(
                    onPressed: () async {
                      await _bottomSheetOuterController.animateTo(
                        2 / 3,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                      if (!context.mounted) return;
                      prepareDownloadConfigView(
                        context,
                        shouldShowConfig: pixels > 33,
                      );
                    },
                    tooltip:
                        pixels <= 33 ? 'Show regions' : 'Configure download',
                    child: pixels <= 33
                        ? const Icon(Icons.library_add_check)
                        : const Icon(Icons.tune),
                  );
                },
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedTab,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Selector<DownloadingProvider, bool>(
                selector: (context, provider) => provider.storeName != null,
                builder: (context, isDownloading, child) =>
                    !isDownloading ? child! : Badge(child: child),
                child: const Icon(Icons.download_outlined),
              ),
              selectedIcon: const Icon(Icons.download),
              label: 'Download',
            ),
            NavigationDestination(
              icon: Selector<RecoverableRegionsProvider, int>(
                selector: (context, provider) => provider.failedRegions.length,
                builder: (context, count, child) => count == 0
                    ? child!
                    : Badge.count(count: count, child: child),
                child: const Icon(Icons.support_outlined),
              ),
              selectedIcon: const Icon(Icons.support),
              label: 'Recovery',
            ),
          ],
          onDestinationSelected: (i) {
            selectedTabState.value = i;
            if (i == 1) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _bottomSheetOuterController.animateTo(
                  32 / constrainedHeight,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                ),
              );
            } else {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _bottomSheetOuterController.animateTo(
                  0.3,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                ),
              );
            }
          },
        ),
      );
}

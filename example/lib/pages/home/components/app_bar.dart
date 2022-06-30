import 'package:badges/badges.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../state/general_provider.dart';
import 'recovery_sheet.dart';

const IconButton checkingRecovery = IconButton(
  icon: Icon(Icons.sync),
  onPressed: null,
  tooltip: 'Checking for recoverable downloads...',
);

AppBar buildAppBar(BuildContext context) {
  return AppBar(
    actions: [
      DescribedFeatureOverlay(
        featureId: 'recoveryChecking',
        tapTarget: const Icon(Icons.sync_problem),
        title: const Text('Automatic Download Recovery'),
        description: const Text(
          'Automatically checks for failed downloads on app startup. If any downloads can be recovered, tap this button to restart them.',
        ),
        contentLocation: ContentLocation.below,
        overflowMode: OverflowMode.extendBackground,
        child: FutureBuilder<Directory>(
          future: MapCachingManager.normalCache,
          builder: (context, cacheDir) {
            if (!cacheDir.hasData) return checkingRecovery;

            return FutureBuilder<List<String>>(
              future: MapCachingManager(cacheDir.data!).allStoresNamesAsync,
              builder: (context, names) {
                if (!names.hasData) return checkingRecovery;

                return FutureBuilder<List<RecoveredRegion?>>(
                  future: Future.wait(names.data!.map((e) =>
                      StorageCachingTileProvider(
                              parentDirectory: cacheDir.data!, storeName: e)
                          .recoverDownload(deleteRecovery: false))),
                  builder: (context, rec) {
                    if (!rec.hasData) return checkingRecovery;

                    final List<RecoveredRegion?> whichRecoverable =
                        rec.data!.where((e) => e != null).toList();
                    if (whichRecoverable.isEmpty) return Container();

                    return IconButton(
                      icon: Badge(
                        child: const Icon(Icons.downloading),
                        toAnimate: false,
                      ),
                      tooltip: 'Recoverable Downloads',
                      onPressed: () => showRecoverySheet(
                        context: context,
                        names: names.data!,
                        allRecoverable: rec.data!,
                        whichRecoverable: whichRecoverable,
                        cacheDir: cacheDir.data!,
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      DescribedFeatureOverlay(
        featureId: 'manageStorage',
        tapTarget: const Icon(Icons.sd_card),
        title: const Text('Manage Caching Stores'),
        description: const Text(
          'The management access point, where you can select the current store to use on the main screen, and perform other actions with stores. Go there now...',
        ),
        onComplete: () async {
          Navigator.pushNamed(context, '/storeManager');
          return true;
        },
        contentLocation: ContentLocation.below,
        overflowMode: OverflowMode.extendBackground,
        child: IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/storeManager');
          },
          icon: const Icon(Icons.sd_card),
          tooltip: 'Manage Caching Stores',
        ),
      ),
    ],
    leading: DescribedFeatureOverlay(
      featureId: 'cachingSwitch',
      tapTarget: const Icon(Icons.offline_bolt),
      title: const Text('Enable/Disable Caching'),
      description: const Text(
        'This switch changes the map on this page between live mode and offline mode.\nIn live mode, any other caching functionality will have no effect, but in offline mode, the map will use the caching tile provider (`StorageCachingTileProvider`) with the currently selected store.',
      ),
      contentLocation: ContentLocation.below,
      overflowMode: OverflowMode.extendBackground,
      child: Tooltip(
        message: 'Enable/Disable Caching',
        child: Switch(
          onChanged: (bool newVal) async {
            final GeneralProvider provider =
                Provider.of<GeneralProvider>(context, listen: false);
            provider.cachingEnabled = newVal;
            provider.resetMap();
            if (newVal) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Caching to: ${provider.storeName}',
                  ),
                  action: SnackBarAction(
                    label: 'Stop Caching',
                    onPressed: () => provider.cachingEnabled = false,
                  ),
                ),
              );
            }
          },
          value: Provider.of<GeneralProvider>(context).cachingEnabled,
        ),
      ),
    ),
    title: const Text('FMTC Demo'),
    elevation: 0,
  );
}

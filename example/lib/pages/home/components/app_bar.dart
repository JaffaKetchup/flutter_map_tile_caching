import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/general_provider.dart';

AppBar buildAppBar(BuildContext context) {
  return AppBar(
    actions: [
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

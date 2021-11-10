import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../../state/general_provider.dart';

AppBar buildAppBar(BuildContext context, PanelController controller) {
  return AppBar(
    actions: [
      IconButton(
        onPressed: () {},
        icon: const Icon(Icons.sd_card),
        tooltip: 'Manage Caching Storess',
      ),
      IconButton(
        onPressed: () {},
        icon: const Icon(Icons.layers),
        tooltip: 'Manage Map Layers',
      ),
    ],
    leading: Tooltip(
      message: 'Enable/Disable Caching',
      child: Switch(
        onChanged: (bool newVal) {
          final GeneralProvider provider =
              Provider.of<GeneralProvider>(context, listen: false);
          provider.cachingEnabled = newVal;
          if (newVal) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Caching to: ${provider.currentMapCachingManager.storeName}',
                ),
                action: SnackBarAction(
                  label: 'Stop Caching',
                  onPressed: () {
                    provider.cachingEnabled = false;
                    controller.hide();
                  },
                ),
              ),
            );
            controller.show();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Caching Disabled')),
            );
            controller.hide();
          }
        },
        value: Provider.of<GeneralProvider>(context).cachingEnabled,
      ),
    ),
    title: const Text('FMTC Demo'),
    elevation: 0,
  );
}

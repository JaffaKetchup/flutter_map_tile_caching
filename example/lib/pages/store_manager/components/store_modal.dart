import 'package:flutter/material.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../state/general_provider.dart';

class StoreModal extends StatelessWidget {
  const StoreModal({
    Key? key,
    required this.currentMCM,
    required this.storeNames,
  }) : super(key: key);

  final MapCachingManager currentMCM;
  final List<String> storeNames;

  @override
  Widget build(BuildContext context) {
    return Consumer<GeneralProvider>(
      builder: (context, provider, _) => Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Download Region'),
              leading: const Icon(Icons.download),
              onTap: () {
                Navigator.popAndPushNamed(
                  context,
                  '/bulkDownloader',
                  arguments: currentMCM,
                );
              },
              visualDensity: VisualDensity.compact,
            ),
            const Divider(),
            ListTile(
              title: const Text('Edit'),
              leading: const Icon(Icons.edit),
              onTap: () {
                Navigator.popAndPushNamed(
                  context,
                  '/storeEditor',
                  arguments: currentMCM,
                );
              },
              visualDensity: VisualDensity.compact,
            ),
            ListTile(
              title: Text(
                'Delete',
                style: provider.storeName == currentMCM.storeName
                    ? null
                    : const TextStyle(color: Colors.red),
              ),
              leading: Icon(
                Icons.delete_forever,
                color: provider.storeName == currentMCM.storeName
                    ? null
                    : Colors.red,
              ),
              onTap: () {
                currentMCM.deleteStore();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${currentMCM.storeName} deleted successfully',
                    ),
                  ),
                );
              },
              visualDensity: VisualDensity.compact,
              enabled: provider.storeName != currentMCM.storeName,
            ),
          ],
        ),
      ),
    );
  }
}

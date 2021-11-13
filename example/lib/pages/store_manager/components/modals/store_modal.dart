import 'package:flutter/material.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../../../state/general_provider.dart';
import 'rename_modal.dart';

class StoreModal extends StatelessWidget {
  const StoreModal({
    Key? key,
    required this.mcm,
    required this.availableStores,
    required this.provider,
  }) : super(key: key);

  final MapCachingManager mcm;
  final List<String> availableStores;
  final GeneralProvider provider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('Download Region'),
            leading: const Icon(Icons.download),
            onTap: () {},
            visualDensity: VisualDensity.compact,
          ),
          const Divider(),
          ListTile(
            title: const Text('Rename'),
            leading: const Icon(Icons.edit),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return RenameModal(mcm: mcm);
                },
              );
            },
            visualDensity: VisualDensity.compact,
          ),
          ListTile(
            title: Text(
              'Delete',
              style: provider.storeName == mcm.storeName
                  ? null
                  : const TextStyle(color: Colors.red),
            ),
            leading: Icon(
              Icons.delete_forever,
              color: provider.storeName == mcm.storeName ? null : Colors.red,
            ),
            onTap: () {
              mcm.deleteStore();
              Navigator.pop(context);
              Navigator.popAndPushNamed(context, '/storeManager');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${mcm.storeName} deleted successfully',
                  ),
                ),
              );
            },
            visualDensity: VisualDensity.compact,
            enabled: provider.storeName != mcm.storeName,
          ),
        ],
      ),
    );
  }
}

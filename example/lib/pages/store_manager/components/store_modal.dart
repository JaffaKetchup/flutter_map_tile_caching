import 'package:flutter/material.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../state/general_provider.dart';

class StoreModal extends StatefulWidget {
  const StoreModal({
    Key? key,
    required this.currentMCM,
    required this.storeNames,
  }) : super(key: key);

  final MapCachingManager currentMCM;
  final List<String> storeNames;

  @override
  State<StoreModal> createState() => _StoreModalState();
}

class _StoreModalState extends State<StoreModal> {
  @override
  Widget build(BuildContext context) {
    return Consumer<GeneralProvider>(
      builder: (context, provider, _) => Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 8.0),
        child: ListView(
          shrinkWrap: true,
          children: [
            if (provider.storeModalCompletedString != null)
              ListTile(
                tileColor: Colors.green,
                iconColor: Colors.white,
                textColor: Colors.white,
                leading: const Icon(Icons.done),
                title: Text(
                  provider.storeModalCompletedString!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Download Region'),
              subtitle: const Text('You must abide by your tile server\'s TOS'),
              leading: const Icon(Icons.download),
              onTap: () {
                Navigator.of(context).popAndPushNamed(
                  '/bulkDownloader',
                  arguments: widget.currentMCM,
                );
              },
              visualDensity: VisualDensity.compact,
            ),
            const Divider(),
            ListTile(
              title: const Text('Edit'),
              leading: const Icon(Icons.edit),
              onTap: () {
                Navigator.of(context).popAndPushNamed(
                  '/storeEditor',
                  arguments: widget.currentMCM,
                );
              },
              visualDensity: VisualDensity.compact,
            ),
            ListTile(
              title: const Text('Empty'),
              leading: const Icon(Icons.delete),
              onTap: () async {
                showModalBottomSheet(
                  isDismissible: false,
                  enableDrag: false,
                  context: context,
                  builder: (context) {
                    return const Padding(
                      padding: EdgeInsets.all(10),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                );
                await widget.currentMCM.emptyStoreAsync();
                provider.storeModalCompletedString = 'Emptied Successfully';
                Navigator.of(context).pop();
              },
              visualDensity: VisualDensity.compact,
            ),
            ListTile(
              title: Text(
                'Delete Permanently',
                style: provider.storeName == widget.currentMCM._storeName
                    ? null
                    : const TextStyle(color: Colors.red),
              ),
              subtitle: provider.storeName != widget.currentMCM._storeName
                  ? null
                  : const Text('Cannot delete store currently in use'),
              leading: Icon(
                Icons.delete_forever,
                color: provider.storeName == widget.currentMCM._storeName
                    ? null
                    : Colors.red,
              ),
              onTap: () async {
                await widget.currentMCM.deleteStoreAsync();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${widget.currentMCM._storeName} deleted successfully'),
                  ),
                );
              },
              visualDensity: VisualDensity.compact,
              enabled: provider.storeName != widget.currentMCM._storeName,
            ),
          ],
        ),
      ),
    );
  }
}

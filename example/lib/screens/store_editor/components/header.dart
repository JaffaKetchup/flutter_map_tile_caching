import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

//import '../../../shared/state/download_provider.dart';
import '../../../shared/state/general_provider.dart';
import '../store_editor.dart';

AppBar buildHeader({
  required StoreEditorPopup widget,
  required bool mounted,
  required GlobalKey<FormState> formKey,
  required Map<String, String> newValues,
  required bool useNewCacheModeValue,
  required String? cacheModeValue,
  required BuildContext context,
}) =>
    AppBar(
      title: Text(
        widget.existingStoreName == null
            ? 'Create New Store'
            : "Edit '${widget.existingStoreName}'",
      ),
      actions: [
        IconButton(
          icon: Icon(
            widget.existingStoreName == null ? Icons.save_as : Icons.save,
          ),
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Saving...'),
                duration: Duration(milliseconds: 1500),
              ),
            );

            // Give the asynchronus validation a chance
            await Future.delayed(const Duration(seconds: 1));
            if (!mounted) return;

            if (formKey.currentState!.validate()) {
              formKey.currentState!.save();

              final existingStore = widget.existingStoreName == null
                  ? null
                  : FMTCStore(widget.existingStoreName!);
              final newStore = existingStore == null
                  ? FMTCStore(newValues['storeName']!)
                  : await existingStore.manage.rename(newValues['storeName']!);
              if (!mounted) return;

              /*final downloadProvider =
                  Provider.of<DownloaderProvider>(context, listen: false);
              if (existingStore != null &&
                  downloadProvider.selectedStore == existingStore) {
                downloadProvider.setSelectedStore(newStore);
              }*/

              if (existingStore == null) await newStore.manage.create();

              // Designed to test both methods, even though only bulk would be
              // more efficient
              await newStore.metadata.set(
                key: 'sourceURL',
                value: newValues['sourceURL']!,
              );
              await newStore.metadata.setBulk(
                kvs: {
                  'validDuration': newValues['validDuration']!,
                  'maxLength': newValues['maxLength']!,
                  if (widget.existingStoreName == null || useNewCacheModeValue)
                    'behaviour': cacheModeValue ?? 'cacheFirst',
                },
              );

              if (!context.mounted) return;
              if (widget.isStoreInUse && widget.existingStoreName != null) {
                Provider.of<GeneralProvider>(context, listen: false)
                    .currentStore = newValues['storeName'];
              }
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved successfully')),
              );
            } else {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please correct the appropriate fields',
                  ),
                ),
              );
            }
          },
        ),
      ],
    );

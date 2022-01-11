import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../state/general_provider.dart';

Future<bool> exit(
  BuildContext context,
  Map<String, List<dynamic>> options,
  GlobalKey<FormState> formKey,
) async {
  // Validate form
  if (!formKey.currentState!.validate()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('One or more fields failed validation')),
    );

    return false;
  }

  // Check no values are empty or 0
  if (options.values.any(
      (element) => element[1] == null || element[1] == '' || element[1] == 0)) {
    // If user forces exit, no changes will be saved
    final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> snackbar =
        ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('One or more fields is empty or zero'),
        action: SnackBarAction(
          label: 'Exit Without Saving',
          onPressed: () {},
        ),
      ),
    );

    if (await snackbar.closed == SnackBarClosedReason.action) {
      return true;
    } else {
      return false;
    }
  } else
  // Check if values haven't been changed
  if (options.values.every((element) => element[0] == element[1])) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No changes were made')),
    );

    return true;
  } else
  // Values have changed
  {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Save Changes?'),
            content: const Text(
                'Would you like to save or discard any changes you\'ve made to this store?'),
            actions: [
              TextButton(
                child: const Text('Save'),
                onPressed: () async {
                  await saveChanges(context, options);
                  Navigator.of(context).pop(true);
                },
              ),
              TextButton(
                child: const Text('Discard'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        )) ??
        false;
  }
}

Future<void> saveChanges(
  BuildContext context,
  Map<String, List<dynamic>> options,
) async {
  final GeneralProvider provider =
      Provider.of<GeneralProvider>(context, listen: false);
  late final String storeName;

  if (options['storeName']![1] != options['storeName']![0]) {
    storeName = options['storeName']![1];

    if (options['storeName']![0] == null) {
      MapCachingManager(provider.parentDirectory!, options['storeName']![1]);
    } else {
      MapCachingManager(provider.parentDirectory!, options['storeName']![0])
          .renameStore(storeName);
    }

    if (provider.storeName == options['storeName']![0]) {
      provider.storeName = storeName;
      await provider.persistent!.setString('lastUsedStore', storeName);
    }
  } else {
    storeName = options['storeName']![0];
  }

  Future<void> _basicPersistenceSaver<T>(String opt) async {
    if (T == String) {
      await provider.persistent!
          .setString('$storeName: $opt', options[opt]![1]);
    } else if (T == int) {
      await provider.persistent!.setInt('$storeName: $opt', options[opt]![1]);
    } else {
      throw FallThroughError();
    }
  }

  await _basicPersistenceSaver<String>('sourceURL');
  await _basicPersistenceSaver<String>('cacheBehaviour');
  await _basicPersistenceSaver<int>('validDuration');
  await _basicPersistenceSaver<int>('maxTiles');
}

import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class FAB extends StatelessWidget {
  const FAB({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () async {
        MapCachingManager(await MapCachingManager.normalCache, 'New Store');
        Navigator.popAndPushNamed(context, '/storeManager');
      },
      label: const Text('Create New Store'),
      icon: const Icon(Icons.create_new_folder),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

Widget buildListTileImage(MapCachingManager mcm) {
  return FutureBuilder<Widget?>(
    future: mcm.storeLength == 0
        ? Future.sync(
            () => const SizedBox(
              height: 50,
              width: 50,
              child: Icon(Icons.help_outline),
            ),
          )
        : mcm.coverImageAsync(
            random: true,
            maxRange: 10,
            size: 50,
          ),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const SizedBox(
          height: 50,
          width: 50,
          child: SizedBox(
            height: 10,
            width: 10,
            child: CircularProgressIndicator(),
          ),
        );
      }

      return snapshot.data!;
    },
  );
}

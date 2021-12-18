import 'package:flutter/material.dart';

AppBar buildAppBar(
  BuildContext context,
) {
  return AppBar(
    title: const Text('Download Region'),
    actions: [
      Builder(
        builder: (context) {
          return IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return const SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Bulk downloading allows a user to pre-fetch/pre-cache tiles in a region.\n\'flutter_map_tile_caching\' has 3 predefined region shapes: rectangle, circle, and line; in that order of efficiency and accuracy. RectangleRegion is created by the north-west and south-east corners of a rectangle. CircleRegion is created by a center and radius of a circle. LineRegion is created by a path and radius, which creates a locus.\nDownloading can be done in the foreground or background, depending on the app\'s permissions and the user\'s needs: find out more on the README.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              );
            },
            icon: const Icon(Icons.help),
          );
        },
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../../state/bulk_download_provider.dart';

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
                builder: _buildInfoPanel,
              );
            },
            icon: const Icon(Icons.help),
          );
        },
      ),
    ],
  );
}

Widget _buildInfoPanel(context) {
  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Scrollbar(
        isAlwaysShown: true,
        thickness: 2,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: RichText(
              textAlign: TextAlign.justify,
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: 'Bulk Downloader\n',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  TextSpan(
                    text: 'This info panel is scrollable\n\n',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  TextSpan(
                    text: 'How to use\n',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text:
                        'Drag the viewfinder over an area you would like to download, and choose a suitable shape using the switch chips. The crosshairs will help you get your real center and will confirm your corner/edge.\nOnce you\'ve decided on your perfect area, tap the Done button and input other information such as zoom levels, number of threads, and other optional functionality. Then start the download and watch the percentage tick up.\n\n',
                  ),
                  TextSpan(
                    text: 'Limitations apply.\n',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text:
                        'Bulk downloading using this manner places a large amount of strain on tile servers as it involves potentially rendering a large amount of new tiles, especially at more detailed zoom levels (> 14).\nTherefore, many tile servers - especially free ones - will state in their Terms of Service that bulk downloading is forbidden. Other servers allow this (or do not state either way), so this functionality is provided anyway.\nAs such, limitations have been enforced in this example app. You cannot: download more than 50000 tiles at once, download at zoom levels above 16, nor use more than 5 download threads.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class FAB extends StatelessWidget {
  const FAB({
    Key? key,
    required this.mcm,
  }) : super(key: key);

  final MapCachingManager mcm;

  @override
  Widget build(BuildContext context) {
    return Consumer<BulkDownloadProvider>(
      builder: (context, bdp, _) {
        return FloatingActionButton(
          onPressed: () => bdp.regionSelected = true,
          child: const Icon(Icons.done),
          tooltip: 'Select Region',
        );
      },
    );
  }
}

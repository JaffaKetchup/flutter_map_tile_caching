import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../map_view.dart';

class Attribution extends StatelessWidget {
  const Attribution({
    super.key,
    required this.urlTemplate,
    required this.mode,
    required this.stores,
    required this.otherStoresStrategy,
  });

  final String urlTemplate;
  final MapViewMode mode;
  final Map<String, BrowseStoreStrategy?> stores;
  final BrowseStoreStrategy? otherStoresStrategy;

  @override
  Widget build(BuildContext context) => RichAttributionWidget(
        alignment: AttributionAlignment.bottomLeft,
        popupInitialDisplayDuration: const Duration(seconds: 3),
        popupBorderRadius: BorderRadius.circular(12),
        attributions: [
          TextSourceAttribution(Uri.parse(urlTemplate).host),
          const TextSourceAttribution(
            'For demonstration purposes only',
            prependCopyright: false,
            textStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSourceAttribution(
            'Offline mapping made with FMTC',
            prependCopyright: false,
            textStyle: TextStyle(fontStyle: FontStyle.italic),
          ),
          LogoSourceAttribution(
            mode == MapViewMode.standard
                ? const Icon(Icons.bug_report)
                : const SizedBox.shrink(),
            tooltip: 'Show resolved store configuration',
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog.adaptive(
                title: const Text('Resolved store configuration'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stores.entries.isEmpty
                          ? 'No stores set explicitly'
                          : stores.entries
                              .map(
                                (e) => '${e.key}: ${e.value ?? 'Explicitly '
                                    'disabled'}',
                              )
                              .join('\n'),
                    ),
                    Text(
                      otherStoresStrategy == null
                          ? 'No other stores in use'
                          : 'All unspecified stores: $otherStoresStrategy',
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Understood'),
                  ),
                ],
              ),
            ),
          ),
          LogoSourceAttribution(
            Image.asset('assets/icons/ProjectIcon.png'),
            tooltip: 'flutter_map_tile_caching',
          ),
        ],
      );
}

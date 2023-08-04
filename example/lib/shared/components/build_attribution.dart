import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

List<Widget> buildStdAttribution(
  String urlTemplate, {
  AttributionAlignment alignment = AttributionAlignment.bottomRight,
}) =>
    [
      RichAttributionWidget(
        alignment: alignment,
        popupInitialDisplayDuration: const Duration(seconds: 3),
        popupBorderRadius: alignment == AttributionAlignment.bottomRight
            ? null
            : BorderRadius.circular(10),
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
            Image.asset('assets/icons/ProjectIcon.png'),
            tooltip: 'flutter_map_tile_caching',
          ),
        ],
      ),
    ];

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class StandardAttribution extends StatelessWidget {
  const StandardAttribution({
    super.key,
    required this.urlTemplate,
    this.alignment = AttributionAlignment.bottomRight,
  });

  final String urlTemplate;
  final AttributionAlignment alignment;

  @override
  Widget build(BuildContext context) => RichAttributionWidget(
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
      );
}

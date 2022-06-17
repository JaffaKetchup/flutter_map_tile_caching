import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../shared/state/download_provider.dart';

class DownloadRegionPopup extends StatefulWidget {
  const DownloadRegionPopup({
    Key? key,
    required this.region,
  }) : super(key: key);

  final BaseRegion region;

  @override
  State<DownloadRegionPopup> createState() => _DownloadRegionPopupState();
}

class _DownloadRegionPopupState extends State<DownloadRegionPopup> {
  late final CircleRegion circleRegion;
  late final RectangleRegion rectangleRegion;

  @override
  void initState() {
    if (widget.region is CircleRegion) {
      circleRegion = widget.region as CircleRegion;
    } else {
      rectangleRegion = widget.region as RectangleRegion;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Download Region'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.region is CircleRegion) ...[
                    const Text('APPROX. CENTER'),
                    Text(
                      '${circleRegion.center.latitude.toStringAsFixed(3)}, ${circleRegion.center.longitude.toStringAsFixed(3)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('RADIUS'),
                    Text(
                      '${circleRegion.radius.toStringAsFixed(2)} km',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ] else ...[
                    const Text('APPROX. NORTH WEST'),
                    Text(
                      '${rectangleRegion.bounds.northWest.latitude.toStringAsFixed(3)}, ${rectangleRegion.bounds.northWest.longitude.toStringAsFixed(3)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('APPROX. SOUTH EAST'),
                    Text(
                      '${rectangleRegion.bounds.southEast.latitude.toStringAsFixed(3)}, ${rectangleRegion.bounds.southEast.longitude.toStringAsFixed(3)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Text('TOTAL TILES'),
                  Consumer<DownloadProvider>(
                    builder: (context, provider, _) =>
                        provider.regionTiles == null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: SizedBox(
                                  height: 36,
                                  width: 36,
                                  child: Center(
                                    child: SizedBox(
                                      height: 28,
                                      width: 28,
                                      child: CircularProgressIndicator(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                '~${provider.regionTiles}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Divider(),
              const SizedBox(height: 5),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Start Foreground Download'),
                ),
              ),
              Row(
                children: [
                  Tooltip(
                    message: 'Request Enhanced Background Permissions',
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Icon(Icons.settings_suggest),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('Start Background Download'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

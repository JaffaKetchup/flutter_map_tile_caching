import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:osm_nominatim/osm_nominatim.dart';

import 'recovery_start_button.dart';

class RecoveryList extends StatefulWidget {
  const RecoveryList({
    super.key,
    required this.all,
    required this.moveToDownloadPage,
  });

  final Iterable<({bool isFailed, RecoveredRegion region})> all;
  final void Function() moveToDownloadPage;

  @override
  State<RecoveryList> createState() => _RecoveryListState();
}

class _RecoveryListState extends State<RecoveryList> {
  @override
  Widget build(BuildContext context) => ListView.builder(
        itemCount: widget.all.length,
        itemBuilder: (context, index) {
          final result = widget.all.elementAt(index);
          final region = result.region;
          final isFailed = result.isFailed;

          return ListTile(
            leading: Icon(
              isFailed ? Icons.warning : Icons.pending_actions,
              color: isFailed ? Colors.red : null,
            ),
            title: Text(
              '${region.storeName} - ${switch (region.toRegion()) {
                RectangleRegion() => 'Rectangle',
                CircleRegion() => 'Circle',
                LineRegion() => 'Line',
                CustomPolygonRegion() => 'Custom Polygon',
              }} Type',
            ),
            subtitle: FutureBuilder<Place>(
              future: Nominatim.reverseSearch(
                lat: region.center?.latitude ??
                    region.bounds?.center.latitude ??
                    region.line?[0].latitude,
                lon: region.center?.longitude ??
                    region.bounds?.center.longitude ??
                    region.line?[0].longitude,
                zoom: 10,
                addressDetails: true,
              ),
              builder: (context, response) => Text(
                'Started at ${region.time} (~${DateTime.timestamp().difference(region.time).inMinutes} minutes ago)\n${response.hasData ? 'Center near ${response.data!.address!['postcode']}, ${response.data!.address!['country']}' : response.hasError ? 'Unable To Reverse Geocode Location' : 'Please Wait...'}',
              ),
            ),
            onTap: () {},
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () async {
                    await FMTCRoot.recovery.cancel(region.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Deleted Recovery Information'),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                RecoveryStartButton(
                  moveToDownloadPage: widget.moveToDownloadPage,
                  result: result,
                ),
              ],
            ),
          );
        },
      );
}

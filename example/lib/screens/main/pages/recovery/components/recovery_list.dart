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

  final List<RecoveredRegion> all;
  final void Function() moveToDownloadPage;

  @override
  State<RecoveryList> createState() => _RecoveryListState();
}

class _RecoveryListState extends State<RecoveryList> {
  @override
  Widget build(BuildContext context) => ListView.builder(
        itemCount: widget.all.length,
        itemBuilder: (context, index) {
          final region = widget.all[index];
          return ListTile(
            leading: FutureBuilder<RecoveredRegion?>(
              future: FMTC.instance.rootDirectory.recovery
                  .getFailedRegion(region.id),
              builder: (context, isFailed) => Icon(
                isFailed.data != null
                    ? Icons.warning
                    : region.type == RegionType.circle
                        ? Icons.circle_outlined
                        : region.type == RegionType.line
                            ? Icons.timeline
                            : Icons.rectangle_outlined,
                color: isFailed.data != null ? Colors.red : null,
              ),
            ),
            title: Text(
              '${region.storeName} - ${region.type.name[0].toUpperCase() + region.type.name.substring(1)} Type',
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
                'Started at ${region.time} (~${DateTime.now().difference(region.time).inMinutes} minutes ago)\n${response.hasData ? 'Center near ${response.data!.address!['postcode']}, ${response.data!.address!['country']}' : response.hasError ? 'Unable To Reverse Geocode Location' : 'Please Wait...'}',
              ),
            ),
            onTap: () {},
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () async {
                    await FMTC.instance.rootDirectory.recovery
                        .cancel(region.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Deleted Recovery Information'),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 10),
                RecoveryStartButton(
                  moveToDownloadPage: widget.moveToDownloadPage,
                  region: region,
                ),
              ],
            ),
          );
        },
      );
}

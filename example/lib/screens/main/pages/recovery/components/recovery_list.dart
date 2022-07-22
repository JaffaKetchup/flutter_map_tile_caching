import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:osm_nominatim/osm_nominatim.dart';

class RecoveryList extends StatefulWidget {
  const RecoveryList({
    Key? key,
    required this.all,
  }) : super(key: key);

  final List<Future<RecoveredRegion>> all;

  @override
  State<RecoveryList> createState() => _RecoveryListState();
}

class _RecoveryListState extends State<RecoveryList> {
  @override
  Widget build(BuildContext context) => ListView.builder(
        itemCount: widget.all.length,
        itemBuilder: (context, index) => FutureBuilder<RecoveredRegion>(
          future: widget.all[index],
          builder: (context, region) => region.hasData
              ? ListTile(
                  leading: FutureBuilder<RecoveredRegion?>(
                    future: FMTC.instance.rootDirectory.recovery
                        .getFailedRegion(region.data!.id),
                    builder: (context, isFailed) => Icon(
                      isFailed.data != null
                          ? Icons.warning
                          : region.data!.type == RegionType.circle
                              ? Icons.circle_outlined
                              : region.data!.type == RegionType.line
                                  ? Icons.timeline
                                  : Icons.rectangle_outlined,
                      color: isFailed.data != null ? Colors.red : null,
                    ),
                  ),
                  title: Text(
                    '${region.data!.storeName} - ${region.data!.type.name[0].toUpperCase() + region.data!.type.name.substring(1)} Type',
                  ),
                  subtitle: FutureBuilder<Place>(
                    future: Nominatim.reverseSearch(
                      lat: region.data!.center?.latitude ??
                          region.data!.bounds?.center.latitude ??
                          region.data!.line?[0].latitude,
                      lon: region.data!.center?.longitude ??
                          region.data!.bounds?.center.longitude ??
                          region.data!.line?[0].longitude,
                      zoom: 10,
                      addressDetails: true,
                    ),
                    builder: (context, response) => response.hasError
                        ? const Text('Unable To Reverse Geocode Location')
                        : response.hasData
                            ? Text(
                                'Near ${response.data!.address!['postcode']}, ${response.data!.address!['country']} (Nominatim)',
                              )
                            : const Text('Please Wait...'),
                  ),
                  onTap: () {},
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: () async {
                          await FMTC.instance.rootDirectory.recovery
                              .cancel(region.data!.id);
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
                      FutureBuilder<RecoveredRegion?>(
                        future: FMTC.instance.rootDirectory.recovery
                            .getFailedRegion(region.data!.id),
                        builder: (context, isFailed) => IconButton(
                          icon: Icon(
                            Icons.download,
                            color: isFailed.data != null ? Colors.green : null,
                          ),
                          onPressed: isFailed.data == null ? null : () {},
                        ),
                      ),
                    ],
                  ),
                )
              : ListTile(
                  leading: const CircularProgressIndicator(),
                  title: const Text('Loading...'),
                  subtitle: const Text('Please Wait...'),
                  onTap: () {},
                ),
        ),
      );
}

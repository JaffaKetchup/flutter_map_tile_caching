import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:fmtc_example/pages/home/components/panel/stat_builder.dart';
import 'package:provider/provider.dart';
import '../../../../state/general_provider.dart';

class Panel extends StatelessWidget {
  const Panel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(8.0),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 10,
      ),
      child: SafeArea(
        child: Consumer<GeneralProvider>(
          builder: (context, provider, _) {
            final MapCachingManager mcm = MapCachingManager(
                provider.parentDirectory!, provider.storeName);

            return StreamBuilder<void>(
              stream: mcm.watchStoreChanges(true)!,
              builder: (context, _) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  statBuilder(
                    stat: mcm.storeLength.toString(),
                    description: 'Total Tiles',
                  ),
                  statBuilder(
                    stat: (mcm.storeSize! / 1024).toStringAsFixed(2) + 'MiB',
                    description: 'Total Size',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/src/publicMisc.dart';

import '../../../../state/general_provider.dart';
import 'stat_builder.dart';

class CollapsedView extends StatelessWidget {
  const CollapsedView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueGrey,
      child: Consumer<GeneralProvider>(
        builder: (context, provider, _) => StreamBuilder<void>(
          stream: provider.currentMapCachingManager.watchChanges,
          builder: (context, snapshot) {
            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  statBuilder(
                    stat: (provider.currentMapCachingManager.storeLength ?? 0)
                        .toString(),
                    description: 'Total Tiles',
                  ),
                  statBuilder(
                    stat: (provider.currentMapCachingManager.storeSize ?? 0)
                            .bytesToMegabytes
                            .toStringAsPrecision(2) +
                        'MB',
                    description: 'Store Size',
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map_tile_caching/src/publicMisc.dart';

import '../../../../state/general_provider.dart';
import 'stat_builder.dart';

class CollapsedView extends StatelessWidget {
  const CollapsedView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GeneralProvider>(
      builder: (context, provider, _) {
        if (!provider.cachingEnabled) {
          return Container(
            color: Colors.blueGrey,
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  Text(
                    'Caching is disabled',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Use the switch to enable caching\nUse the SD-card button to manage stores',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          color: Colors.blueGrey,
          child: StreamBuilder<void>(
            stream: provider.currentMapCachingManager.watchChanges,
            builder: (context, snapshot) {
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Container(
                      height: 5,
                      width: MediaQuery.of(context).size.width / 6,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        statBuilder(
                          stat:
                              (provider.currentMapCachingManager.storeLength ??
                                      0)
                                  .toString(),
                          description: 'Total Tiles',
                        ),
                        statBuilder(
                          stat:
                              (provider.currentMapCachingManager.storeSize ?? 0)
                                      .bytesToMegabytes
                                      .toStringAsPrecision(2) +
                                  'MB',
                          description: 'Store Size',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

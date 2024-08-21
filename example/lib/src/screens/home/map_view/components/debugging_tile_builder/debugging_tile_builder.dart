import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

part 'info_display.dart';
part 'result_dialogs.dart';

class DebuggingTileBuilder extends StatelessWidget {
  const DebuggingTileBuilder({
    super.key,
    required this.tileWidget,
    required this.tile,
    required this.tileLoadingDebugger,
    required this.usingFMTC,
  });

  final Widget tileWidget;
  final TileImage tile;
  final ValueNotifier<TileLoadingInterceptorMap> tileLoadingDebugger;
  final bool usingFMTC;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black.withOpacity(0.8),
                width: 2,
              ),
              color: Colors.white.withOpacity(0.5),
            ),
            position: DecorationPosition.foreground,
            child: tileWidget,
          ),
          if (!usingFMTC)
            const OverflowBox(
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.disabled_by_default_rounded, size: 32),
                    SizedBox(height: 6),
                    Text('FMTC not in use'),
                  ],
                ),
              ),
            )
          else
            ValueListenableBuilder(
              valueListenable: tileLoadingDebugger,
              builder: (context, value, _) {
                if (value[tile.coordinates] case final info?) {
                  return _ResultDisplay(tile: tile, fmtcResult: info);
                }

                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              },
            ),
        ],
      );
}

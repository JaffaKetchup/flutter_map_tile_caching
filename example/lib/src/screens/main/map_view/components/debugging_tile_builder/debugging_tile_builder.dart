import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

part 'info_display.dart';
part 'result_dialogs.dart';

class DebuggingTileBuilder extends StatefulWidget {
  const DebuggingTileBuilder({
    super.key,
    required this.tileWidget,
    required this.tile,
    required this.tileLoadingDebugger,
  });

  final Widget tileWidget;
  final TileImage tile;
  final ValueNotifier<TileLoadingInterceptorMap> tileLoadingDebugger;

  @override
  State<DebuggingTileBuilder> createState() => _DebuggingTileBuilderState();
}

class _DebuggingTileBuilderState extends State<DebuggingTileBuilder> {
  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.8),
                width: 2,
              ),
              color: Colors.white.withValues(alpha: 0.5),
            ),
            position: DecorationPosition.foreground,
            child: widget.tileWidget,
          ),
          ValueListenableBuilder(
            valueListenable: widget.tileLoadingDebugger,
            builder: (context, value, _) {
              if (value[widget.tile.coordinates] case final info?) {
                return _ResultDisplay(tile: widget.tile, fmtcResult: info);
              }

              return const Center(
                child: CircularProgressIndicator.adaptive(),
              );
            },
          ),
        ],
      );
}

part of '../parent.dart';

class _AdditionalPane extends StatelessWidget {
  const _AdditionalPane({
    required this.constraints,
    required this.layoutDirection,
  });

  final BoxConstraints constraints;
  final Axis layoutDirection;

  @override
  Widget build(BuildContext context) => Consumer<DownloaderProvider>(
        builder: (context, provider, _) => Stack(
          fit: StackFit.passthrough,
          children: [
            _SliderPanelBase(
              constraints: constraints,
              layoutDirection: layoutDirection,
              isVisible: provider.regionType == RegionType.line,
              child: layoutDirection == Axis.vertical
                  ? IntrinsicWidth(
                      child: LineRegionPane(layoutDirection: layoutDirection),
                    )
                  : IntrinsicHeight(
                      child: LineRegionPane(layoutDirection: layoutDirection),
                    ),
            ),
            _SliderPanelBase(
              constraints: constraints,
              layoutDirection: layoutDirection,
              isVisible: provider.openAdjustZoomLevelsSlider,
              child: AdjustZoomLvlsPane(layoutDirection: layoutDirection),
            ),
          ],
        ),
      );
}

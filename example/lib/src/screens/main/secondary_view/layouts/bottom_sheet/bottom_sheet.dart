import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/download_provider.dart';
import '../../../../../shared/state/region_selection_provider.dart';
import '../../contents/download_configuration/download_configuration_view_bottom_sheet.dart';
import '../../contents/downloading/downloading_view_bottom_sheet.dart';
import '../../contents/home/home_view_bottom_sheet.dart';
import '../../contents/recovery/recovery_view_bottom_sheet.dart';
import '../../contents/region_selection/region_selection_view_bottom_sheet.dart';
import 'components/delayed_frame_attached_dependent_builder.dart';
import 'components/scrollable_provider.dart';

class SecondaryViewBottomSheet extends StatefulWidget {
  const SecondaryViewBottomSheet({
    super.key,
    required this.selectedTab,
    required this.controller,
  });

  final int selectedTab;
  final DraggableScrollableController controller;

  static const topPadding = kMinInteractiveDimension / 1.5;

  @override
  State<SecondaryViewBottomSheet> createState() =>
      _SecondaryViewBottomSheetState();
}

class _SecondaryViewBottomSheetState extends State<SecondaryViewBottomSheet> {
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: PointerDeviceKind.values.toSet(),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => DraggableScrollableSheet(
              initialChildSize: 0.3,
              minChildSize: 32 / constraints.maxHeight,
              snap: true,
              expand: false,
              snapSizes: const [0.3],
              controller: widget.controller,
              builder: (context, innerController) =>
                  DelayedControllerAttachmentBuilder(
                listenable: widget.controller,
                builder: (context, child) {
                  final screenTopPadding =
                      MediaQueryData.fromView(View.of(context)).padding.top;

                  final double paddingPusherHeight =
                      widget.controller.isAttached
                          ? (screenTopPadding -
                                  constraints.maxHeight +
                                  widget.controller.pixels)
                              .clamp(0, screenTopPadding)
                          : 0;

                  return Column(
                    children: [
                      // Widget which pushes the contents out of the way of the
                      // system insets/padding
                      DelayedControllerAttachmentBuilder(
                        listenable: innerController,
                        builder: (context, _) => SizedBox(
                          height: paddingPusherHeight,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            color: innerController.hasClients &&
                                    innerController.offset != 0
                                ? Theme.of(context).colorScheme.surfaceContainer
                                : Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ColoredBox(
                          color: Theme.of(context).colorScheme.surface,
                          child: child,
                        ),
                      ),
                    ],
                  );
                },
                child: BottomSheetScrollableProvider(
                  innerScrollController: innerController,
                  outerScrollController: widget.controller,
                  child: SizedBox(
                    width: double.infinity,
                    child: switch (widget.selectedTab) {
                      0 => const HomeViewBottomSheet(),
                      1 => context.select<DownloadingProvider, bool>(
                          (p) => p.isFocused,
                        )
                            ? const DownloadingViewBottomSheet()
                            : context.select<RegionSelectionProvider, bool>(
                                (p) => p.isDownloadSetupPanelVisible,
                              )
                                ? const DownloadConfigurationViewBottomSheet()
                                : const RegionSelectionViewBottomSheet(),
                      2 => const RecoveryViewBottomSheet(),
                      _ => Placeholder(key: ValueKey(widget.selectedTab)),
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

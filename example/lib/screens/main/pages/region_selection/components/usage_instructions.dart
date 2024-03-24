import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/misc/region_selection_method.dart';
import '../../../../../shared/misc/region_type.dart';
import '../state/region_selection_provider.dart';

class UsageInstructions extends StatelessWidget {
  UsageInstructions({
    super.key,
    required this.constraints,
  }) : layoutDirection =
            constraints.maxWidth > 1325 ? Axis.vertical : Axis.horizontal;

  final BoxConstraints constraints;
  final Axis layoutDirection;

  @override
  Widget build(BuildContext context) => Align(
        alignment: layoutDirection == Axis.vertical
            ? Alignment.centerRight
            : Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(
            left: layoutDirection == Axis.vertical ? 0 : 24,
            right: layoutDirection == Axis.vertical ? 164 : 24,
            top: 24,
            bottom: layoutDirection == Axis.vertical ? 24 : 0,
          ),
          child: FittedBox(
            child: IgnorePointer(
              child: DefaultTextStyle(
                style: GoogleFonts.ubuntu(
                  fontSize: 20,
                  color: Colors.white,
                ),
                child: Consumer<RegionSelectionProvider>(
                  builder: (context, provider, _) => AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    opacity: provider.coordinates.isEmpty ? 1 : 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            spreadRadius: 50,
                            blurRadius: 90,
                          ),
                        ],
                      ),
                      child: Flex(
                        direction: layoutDirection,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: layoutDirection == Axis.vertical
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        textDirection: layoutDirection == Axis.vertical
                            ? null
                            : TextDirection.rtl,
                        children: [
                          Icon(
                            provider.regionSelectionMethod ==
                                    RegionSelectionMethod.usePointer
                                ? Icons.ads_click
                                : Icons.filter_center_focus,
                            size: 60,
                          ),
                          const SizedBox.square(dimension: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AutoSizeText(
                                provider.regionSelectionMethod ==
                                        RegionSelectionMethod.usePointer
                                    ? '@ Pointer'
                                    : '@ Map Center',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                              ),
                              const SizedBox.square(dimension: 2),
                              AutoSizeText(
                                'Tap/click to add ${provider.regionType == RegionType.circle ? 'center' : 'point'}',
                                maxLines: 1,
                              ),
                              AutoSizeText(
                                provider.regionType == RegionType.circle
                                    ? 'Tap/click again to set radius'
                                    : 'Hold/right-click to remove last point',
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../../../shared/misc/exts/interleave.dart';
import '../../../../../configure_download/configure_download.dart';
import '../../../state/region_selection_provider.dart';

part 'additional_panes/additional_pane.dart';
part 'additional_panes/adjust_zoom_lvls_pane.dart';
part 'additional_panes/line_region_pane.dart';
part 'additional_panes/slider_panel_base.dart';
part 'custom_slider_track_shape.dart';
part 'primary_pane.dart';
part 'region_shape_button.dart';

class RegionSelectionSidePanel extends StatelessWidget {
  const RegionSelectionSidePanel({
    super.key,
    required this.bottomPaddingWrapperBuilder,
    required Axis layoutDirection,
  }) : layoutDirection =
            layoutDirection == Axis.vertical ? Axis.horizontal : Axis.vertical;

  final Widget Function(BuildContext context, Widget child)?
      bottomPaddingWrapperBuilder;
  final Axis layoutDirection;

  void finalizeSelection(BuildContext context) =>
      Navigator.of(context).pushNamed(ConfigureDownloadPopup.route);

  @override
  Widget build(BuildContext context) {
    final Widget child;

    if (layoutDirection == Axis.vertical) {
      child = LayoutBuilder(
        builder: (context, constraints) => IntrinsicHeight(
          child: _PrimaryPane(
            constraints: constraints,
            layoutDirection: layoutDirection,
            finalizeSelection: finalizeSelection,
          ),
        ),
      );
    } else {
      final subChild = LayoutBuilder(
        builder: (context, constraints) => IntrinsicWidth(
          child: _PrimaryPane(
            constraints: constraints,
            layoutDirection: layoutDirection,
            finalizeSelection: finalizeSelection,
          ),
        ),
      );

      if (bottomPaddingWrapperBuilder != null) {
        child = Builder(
          builder: (context) => bottomPaddingWrapperBuilder!(context, subChild),
        );
      } else {
        child = subChild;
      }
    }

    return Center(child: FittedBox(child: child));
  }
}

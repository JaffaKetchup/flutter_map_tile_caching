import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../../../shared/misc/exts/interleave.dart';
import '../../../../../../shared/misc/region_selection_method.dart';
import '../../../../../../shared/misc/region_type.dart';
import '../../state/region_selection_provider.dart';

part 'additional_panes/additional_pane.dart';
part 'additional_panes/adjust_zoom_lvls_pane.dart';
part 'additional_panes/line_region_pane.dart';
part 'additional_panes/slider_panel_base.dart';
part 'custom_slider_track_shape.dart';
part 'primary_pane.dart';
part 'region_shape_button.dart';

class SidePanel extends StatelessWidget {
  SidePanel({
    super.key,
    required this.constraints,
    required this.pushToConfigureDownload,
  }) : layoutDirection =
            constraints.maxWidth > 850 ? Axis.vertical : Axis.horizontal;

  final BoxConstraints constraints;
  final void Function() pushToConfigureDownload;

  final Axis layoutDirection;

  @override
  Widget build(BuildContext context) => PositionedDirectional(
        top: layoutDirection == Axis.vertical ? 12 : null,
        bottom: 12,
        start: layoutDirection == Axis.vertical ? 24 : 12,
        end: layoutDirection == Axis.vertical ? null : 12,
        child: Center(
          child: FittedBox(
            child: layoutDirection == Axis.vertical
                ? IntrinsicHeight(
                    child: _PrimaryPane(
                      constraints: constraints,
                      layoutDirection: layoutDirection,
                      pushToConfigureDownload: pushToConfigureDownload,
                    ),
                  )
                : IntrinsicWidth(
                    child: _PrimaryPane(
                      constraints: constraints,
                      layoutDirection: layoutDirection,
                      pushToConfigureDownload: pushToConfigureDownload,
                    ),
                  ),
          ),
        ),
      );
}

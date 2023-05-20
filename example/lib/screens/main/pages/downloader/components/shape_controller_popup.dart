import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/download_provider.dart';
import '../../../../../shared/vars/region_mode.dart';

class ShapeControllerPopup extends StatelessWidget {
  const ShapeControllerPopup({super.key});

  static const Map<String, ({IconData icon, RegionMode mode, String? hint})>
      regionShapes = {
    'Square': (
      icon: Icons.crop_square_sharp,
      mode: RegionMode.square,
      hint: null,
    ),
    'Vertical Rectangle': (
      icon: Icons.crop_portrait_sharp,
      mode: RegionMode.rectangleVertical,
      hint: null,
    ),
    'Horizontal Rectangle': (
      icon: Icons.crop_landscape_sharp,
      mode: RegionMode.rectangleHorizontal,
      hint: null,
    ),
    'Circle': (
      icon: Icons.circle_outlined,
      mode: RegionMode.circle,
      hint: null,
    ),
    'Line/Path': (
      icon: Icons.timeline,
      mode: RegionMode.line,
      hint:
          'Tap/click to add point to line\nHold/secondary click to remove last point from line',
    ),
  };

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Consumer<DownloadProvider>(
          builder: (context, provider, _) => ListView.builder(
            itemCount: regionShapes.length,
            shrinkWrap: true,
            itemBuilder: (context, i) {
              final value = regionShapes.values.elementAt(i);
              return ListTile(
                visualDensity: VisualDensity.compact,
                title: Text(regionShapes.keys.elementAt(i)),
                leading: Icon(value.icon),
                trailing: provider.regionMode == value.mode
                    ? const Icon(Icons.done)
                    : null,
                subtitle: value.hint != null ? Text(value.hint!) : null,
                onTap: () {
                  provider.regionMode = value.mode;
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      );
}

import 'package:flutter/material.dart';

import '../../layouts/side/components/panel.dart';
import 'components/shape_selector.dart';

class RegionSelectionViewSide extends StatelessWidget {
  const RegionSelectionViewSide({super.key});

  @override
  Widget build(BuildContext context) => const Column(
        children: [
          SideViewPanel(child: ShapeSelector()),
        ],
      );
}

// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/bulk_download_provider.dart';

enum RegionMode {
  Square,
  Rectangle,
  Circle,
}

class RegionModeChips extends StatelessWidget {
  const RegionModeChips({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<BulkDownloadProvider>(
      builder: (context, bdp, _) => SafeArea(
        child: ListView.separated(
          itemCount: RegionMode.values.length,
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemBuilder: (context, index) => FilterChip(
            label: Text(RegionMode.values[index].name),
            selected: bdp.mode.index == index,
            onSelected: (_) => bdp.mode = RegionMode.values[index],
            backgroundColor: Colors.white,
            selectedColor: Colors.orange,
            avatar: Icon(index == 0
                ? Icons.crop_square
                : index == 1
                    ? Icons.aspect_ratio
                    : Icons.circle_outlined),
          ),
          separatorBuilder: (context, _) => const SizedBox(width: 5),
        ),
      ),
    );
  }
}

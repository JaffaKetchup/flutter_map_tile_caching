import 'package:flutter/material.dart';

import 'components/recoverable_regions_list/recoverable_regions_list.dart';

class RecoveryViewSide extends StatelessWidget {
  const RecoveryViewSide({super.key});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          color: Theme.of(context).colorScheme.surface,
        ),
        width: double.infinity,
        height: double.infinity,
        child: const CustomScrollView(slivers: [RecoverableRegionsList()]),
      );
}

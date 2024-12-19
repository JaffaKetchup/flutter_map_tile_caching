import 'package:flutter/material.dart';

import '../../layouts/bottom_sheet/components/scrollable_provider.dart';
import '../../layouts/bottom_sheet/utils/tab_header.dart';

class DownloadConfigurationViewBottomSheet extends StatelessWidget {
  const DownloadConfigurationViewBottomSheet({super.key});

  @override
  Widget build(BuildContext context) => CustomScrollView(
        controller:
            BottomSheetScrollableProvider.innerScrollControllerOf(context),
        slivers: const [
          TabHeader(title: 'Download Configuration'),
          SliverToBoxAdapter(child: SizedBox(height: 6)),
        ],
      );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/state/download_configuration_provider.dart';
import '../../../../../shared/state/region_selection_provider.dart';
import '../../../../../shared/state/selected_tab_state.dart';
import '../../layouts/bottom_sheet/components/scrollable_provider.dart';
import '../../layouts/bottom_sheet/utils/tab_header.dart';
import 'components/config_options/config_options.dart';
import 'components/confirmation_panel/confirmation_panel.dart';

class DownloadConfigurationViewBottomSheet extends StatelessWidget {
  const DownloadConfigurationViewBottomSheet({super.key});

  @override
  Widget build(BuildContext context) => CustomScrollView(
        controller:
            BottomSheetScrollableProvider.innerScrollControllerOf(context),
        slivers: [
          const TabHeader(title: 'Download Configuration'),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(99),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  final regionSelectionProvider =
                      context.read<RegionSelectionProvider>();
                  final downloadConfigProvider =
                      context.read<DownloadConfigurationProvider>();

                  regionSelectionProvider.isDownloadSetupPanelVisible = false;

                  if (downloadConfigProvider.fromRecovery == null) return;

                  regionSelectionProvider.clearConstructedRegions();
                  downloadConfigProvider.fromRecovery = null;

                  selectedTabState.value = 2;
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Return to selection'),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8) +
                  const EdgeInsets.symmetric(horizontal: 16),
              child: const ConfigOptions(),
            ),
          ),
          const SliverToBoxAdapter(child: Divider()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8) +
                  const EdgeInsets.symmetric(horizontal: 16),
              child: const ConfirmationPanel(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ],
      );
}

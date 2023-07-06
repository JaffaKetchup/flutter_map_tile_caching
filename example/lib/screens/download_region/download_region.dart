import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';
//import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/state/download_provider.dart';
import '../../shared/state/general_provider.dart';
import 'components/region_information.dart';
import 'components/section_separator.dart';
import 'components/store_selector.dart';

class DownloadRegionPopup extends StatefulWidget {
  const DownloadRegionPopup({
    super.key,
    required this.region,
  });

  final BaseRegion region;

  @override
  State<DownloadRegionPopup> createState() => _DownloadRegionPopupState();
}

class _DownloadRegionPopupState extends State<DownloadRegionPopup> {
  bool isReady = false;

  @override
  void didChangeDependencies() {
    final String? currentStore =
        Provider.of<GeneralProvider>(context, listen: false).currentStore;
    if (currentStore != null) {
      Provider.of<DownloadProvider>(context, listen: false)
          .setSelectedStore(FMTC.instance(currentStore), notify: false);
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) => Consumer<DownloadProvider>(
        builder: (context, provider, _) => Scaffold(
          appBar: AppBar(title: const Text('Configure Bulk Download')),
          floatingActionButton: provider.selectedStore == null
              ? null
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedScale(
                      scale: isReady ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInCubic,
                      alignment: Alignment.bottomRight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onBackground,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        margin: const EdgeInsets.only(right: 12, left: 32),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "You must abide by your tile server's Terms of Service when bulk downloading. Many servers will forbid or heavily restrict this action, as it places extra strain on resources. Be respectful, and note that you use this functionality at your own risk.",
                              textAlign: TextAlign.end,
                              style: TextStyle(color: Colors.black),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'CAUTION',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.report,
                                  color: Colors.red,
                                  size: 32,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FloatingActionButton.extended(
                      onPressed: () async {
                        if (!isReady) {
                          setState(() => isReady = true);
                          return;
                        }
                        final Map<String, String> metadata =
                            await provider.selectedStore!.metadata.readAsync;

                        provider.setDownloadProgress(
                          provider.selectedStore!.download
                              .startForeground(
                                region: widget.region.toDownloadable(
                                  provider.minZoom,
                                  provider.maxZoom,
                                  TileLayer(
                                    urlTemplate: metadata['sourceURL'],
                                    userAgentPackageName:
                                        'dev.jaffaketchup.fmtc.demo',
                                  ),
                                ),
                                parallelThreads: provider.parallelThreads,
                                maxBufferLength: provider.bufferingAmount,
                                skipExistingTiles: provider.skipExistingTiles,
                                skipSeaTiles: provider.skipSeaTiles,
                                rateLimit: provider.rateLimit,
                                disableRecovery: provider.disableRecovery,
                              )
                              .asBroadcastStream(),
                        );

                        if (mounted) Navigator.of(context).pop();
                      },
                      label: const Text('Start Download'),
                      icon: Icon(isReady ? Icons.save : Icons.arrow_forward),
                    ),
                  ],
                ),
          body: Stack(
            children: [
              Positioned.fill(
                left: 12,
                top: 12,
                right: 12,
                bottom: 12,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RegionInformation(region: widget.region),
                      const SectionSeparator(),
                      const StoreSelector(),
                      const SectionSeparator(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CONFIGURE DOWNLOAD OPTIONS'),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text('Parallel Threads'),
                              const Spacer(),
                              Icon(
                                Icons.lock,
                                color: provider.parallelThreads == 10
                                    ? Colors.amber
                                    : Colors.white.withOpacity(0.2),
                              ),
                              const SizedBox(width: 16),
                              IntrinsicWidth(
                                child: TextFormField(
                                  initialValue: '5',
                                  textAlign: TextAlign.end,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    counterText: '',
                                    suffixText: ' threads',
                                  ),
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly,
                                    const NumericalRangeFormatter(
                                      min: 1,
                                      max: 10,
                                    ),
                                  ],
                                  onChanged: (value) =>
                                      provider.parallelThreads =
                                          int.tryParse(value) ??
                                              provider.parallelThreads,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Rate Limit'),
                              const Spacer(),
                              Icon(
                                Icons.lock,
                                color: provider.rateLimit == 200
                                    ? Colors.amber
                                    : Colors.white.withOpacity(0.2),
                              ),
                              const SizedBox(width: 16),
                              IntrinsicWidth(
                                child: TextFormField(
                                  initialValue: '200',
                                  textAlign: TextAlign.end,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    counterText: '',
                                    suffixText: ' max. tiles/second',
                                  ),
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly,
                                    const NumericalRangeFormatter(
                                      min: 1,
                                      max: 200,
                                    ),
                                  ],
                                  onChanged: (value) => provider.rateLimit =
                                      int.tryParse(value) ?? provider.rateLimit,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Tile Buffer Length'),
                              const Spacer(),
                              IntrinsicWidth(
                                child: TextFormField(
                                  initialValue: '200',
                                  textAlign: TextAlign.end,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    counterText: '',
                                    suffixText: ' tiles',
                                  ),
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly,
                                    const NumericalRangeFormatter(
                                      min: 0,
                                      max: 9223372036854775807,
                                    ),
                                  ],
                                  onChanged: (value) =>
                                      provider.bufferingAmount =
                                          int.tryParse(value) ??
                                              provider.bufferingAmount,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text('Skip Existing Tiles'),
                              const Spacer(),
                              Switch(
                                value: provider.skipExistingTiles,
                                onChanged: (val) =>
                                    provider.skipExistingTiles = val,
                                activeColor:
                                    Theme.of(context).colorScheme.primary,
                              )
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Skip Sea Tiles'),
                              const Spacer(),
                              Switch(
                                value: provider.skipSeaTiles,
                                onChanged: (val) => provider.skipSeaTiles = val,
                                activeColor:
                                    Theme.of(context).colorScheme.primary,
                              )
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !isReady,
                  child: GestureDetector(
                    onTap:
                        isReady ? () => setState(() => isReady = false) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInCubic,
                      color: isReady
                          ? Colors.black.withOpacity(2 / 3)
                          : Colors.transparent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class NumericalRangeFormatter extends TextInputFormatter {
  const NumericalRangeFormatter({required this.min, required this.max});
  final int min;
  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final int parsed = int.parse(newValue.text);

    if (parsed < min) {
      return TextEditingValue.empty.copyWith(
        text: min.toString(),
        selection: TextSelection.collapsed(offset: min.toString().length),
      );
    }
    if (parsed > max) {
      return TextEditingValue.empty.copyWith(
        text: max.toString(),
        selection: TextSelection.collapsed(offset: max.toString().length),
      );
    }

    return newValue;
  }
}

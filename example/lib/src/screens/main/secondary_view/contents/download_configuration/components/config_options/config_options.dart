import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../shared/state/download_configuration_provider.dart';
import 'components/store_selector.dart';

class ConfigOptions extends StatefulWidget {
  const ConfigOptions({super.key});

  @override
  State<ConfigOptions> createState() => _ConfigOptionsState();
}

class _ConfigOptionsState extends State<ConfigOptions> {
  @override
  Widget build(BuildContext context) {
    final storeName = context.select<DownloadConfigurationProvider, String?>(
      (p) => p.selectedStoreName,
    );
    final minZoom =
        context.select<DownloadConfigurationProvider, int>((p) => p.minZoom);
    final maxZoom =
        context.select<DownloadConfigurationProvider, int>((p) => p.maxZoom);
    final parallelThreads = context
        .select<DownloadConfigurationProvider, int>((p) => p.parallelThreads);
    final rateLimit =
        context.select<DownloadConfigurationProvider, int>((p) => p.rateLimit);
    final maxBufferLength = context
        .select<DownloadConfigurationProvider, int>((p) => p.maxBufferLength);

    return SingleChildScrollView(
      child: Column(
        children: [
          StoreSelector(
            storeName: storeName,
            onStoreNameSelected: (storeName) => context
                .read<DownloadConfigurationProvider>()
                .selectedStoreName = storeName,
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Tooltip(message: 'Zoom Levels', child: Icon(Icons.search)),
              const SizedBox(width: 8),
              Expanded(
                child: RangeSlider(
                  values: RangeValues(minZoom.toDouble(), maxZoom.toDouble()),
                  labels: RangeLabels(minZoom.toString(), maxZoom.toString()),
                  max: 20,
                  divisions: 20,
                  onChanged: (r) =>
                      context.read<DownloadConfigurationProvider>()
                        ..minZoom = r.start.toInt()
                        ..maxZoom = r.end.toInt(),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Tooltip(
                message: 'Parallel Threads',
                child: Icon(Icons.call_split),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Slider(
                  value: parallelThreads.toDouble(),
                  label: '$parallelThreads threads',
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (r) => context
                      .read<DownloadConfigurationProvider>()
                      .parallelThreads = r.toInt(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Tooltip(
                message: 'Rate Limit',
                child: Icon(Icons.speed),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Slider(
                  min: 1,
                  value: rateLimit.toDouble(),
                  label: '$rateLimit tps',
                  max: 200,
                  divisions: 199,
                  onChanged: (r) => context
                      .read<DownloadConfigurationProvider>()
                      .rateLimit = r.toInt(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Tooltip(
                message: 'Max Buffer Length',
                child: Icon(Icons.memory),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Slider(
                  value: maxBufferLength.toDouble(),
                  label: maxBufferLength == 0
                      ? 'Disabled'
                      : '$maxBufferLength tiles',
                  max: 1000,
                  divisions: 1000,
                  onChanged: (r) => context
                      .read<DownloadConfigurationProvider>()
                      .maxBufferLength = r.toInt(),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.skip_next),
              const SizedBox(width: 4),
              const Icon(Icons.file_copy),
              const SizedBox(width: 12),
              const Text('Skip Existing Tiles'),
              const Spacer(),
              Switch.adaptive(value: true, onChanged: (value) {}),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.skip_next),
              const SizedBox(width: 4),
              const Icon(Icons.waves),
              const SizedBox(width: 12),
              const Text('Skip Sea Tiles'),
              const Spacer(),
              Switch.adaptive(value: true, onChanged: (value) {}),
            ],
          ),
        ],
      ),
    );
  }
}

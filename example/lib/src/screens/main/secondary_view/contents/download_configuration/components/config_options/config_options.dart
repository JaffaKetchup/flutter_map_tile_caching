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
                  max: 20,
                  divisions: 20,
                  onChanged: (r) =>
                      context.read<DownloadConfigurationProvider>()
                        ..minZoom = r.start.toInt()
                        ..maxZoom = r.end.toInt(),
                ),
              ),
              Text(
                '${minZoom.toString().padLeft(2, '0')} - '
                '${maxZoom.toString().padLeft(2, '0')}',
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
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (r) => context
                      .read<DownloadConfigurationProvider>()
                      .parallelThreads = r.toInt(),
                ),
              ),
              SizedBox(
                width: 71,
                child: Text(
                  '$parallelThreads threads',
                  textAlign: TextAlign.end,
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
                  max: 200,
                  divisions: 199,
                  onChanged: (r) => context
                      .read<DownloadConfigurationProvider>()
                      .rateLimit = r.toInt(),
                ),
              ),
              SizedBox(
                width: 71,
                child: Text(
                  '$rateLimit tps',
                  textAlign: TextAlign.end,
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
                  max: 1000,
                  divisions: 1000,
                  onChanged: (r) => context
                      .read<DownloadConfigurationProvider>()
                      .maxBufferLength = r.toInt(),
                ),
              ),
              SizedBox(
                width: 71,
                child: Text(
                  maxBufferLength == 0 ? 'Disabled' : '$maxBufferLength tiles',
                  textAlign: TextAlign.end,
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

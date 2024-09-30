import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../shared/state/download_configuration_provider.dart';
import '../../../../../../../shared/state/region_selection_provider.dart';

class ConfigOptions extends StatefulWidget {
  const ConfigOptions({super.key});

  @override
  State<ConfigOptions> createState() => _ConfigOptionsState();
}

class _ConfigOptionsState extends State<ConfigOptions> {
  @override
  Widget build(BuildContext context) {
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
          const Divider(),
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
                  max: 10,
                  divisions: 10,
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
        ],
      ),
    );
  }
}

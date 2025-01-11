import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../shared/state/download_configuration_provider.dart';
import 'components/store_selector.dart';

part 'components/slider_option.dart';
part 'components/toggle_option.dart';

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
    final skipExistingTiles =
        context.select<DownloadConfigurationProvider, bool>(
      (p) => p.skipExistingTiles,
    );
    final skipSeaTiles = context
        .select<DownloadConfigurationProvider, bool>((p) => p.skipSeaTiles);
    final retryFailedRequestTiles =
        context.select<DownloadConfigurationProvider, bool>(
      (p) => p.retryFailedRequestTiles,
    );
    final fromRecovery = context
        .select<DownloadConfigurationProvider, int?>((p) => p.fromRecovery);

    return Column(
      children: [
        StoreSelector(
          storeName: storeName,
          onStoreNameSelected: (storeName) => context
              .read<DownloadConfigurationProvider>()
              .selectedStoreName = storeName,
          enabled: fromRecovery == null,
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
                onChanged: fromRecovery != null
                    ? null
                    : (r) => context.read<DownloadConfigurationProvider>()
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
        _SliderOption(
          icon: const Icon(Icons.call_split),
          tooltipMessage: 'Parallel Threads',
          descriptor: 'threads',
          value: parallelThreads,
          min: 1,
          max: 10,
          onChanged: (v) =>
              context.read<DownloadConfigurationProvider>().parallelThreads = v,
        ),
        const SizedBox(height: 8),
        _SliderOption(
          icon: const Icon(Icons.speed),
          tooltipMessage: 'Rate Limit',
          descriptor: 'tps max',
          value: rateLimit,
          min: 1,
          max: 200,
          onChanged: (v) =>
              context.read<DownloadConfigurationProvider>().rateLimit = v,
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
        _ToggleOption(
          icon: const Icon(Icons.file_copy),
          title: 'Skip Existing Tiles',
          description: "Don't attempt tiles that are already cached",
          value: skipExistingTiles,
          onChanged: (v) => context
              .read<DownloadConfigurationProvider>()
              .skipExistingTiles = v,
        ),
        const SizedBox(height: 8),
        _ToggleOption(
          icon: const Icon(Icons.waves),
          title: 'Skip Sea Tiles',
          description:
              "Don't cache tiles with sea/ocean fill as the only visible "
              'element',
          value: skipSeaTiles,
          onChanged: (v) =>
              context.read<DownloadConfigurationProvider>().skipSeaTiles = v,
        ),
        const SizedBox(height: 8),
        _ToggleOption(
          icon: const Icon(Icons.plus_one),
          title: 'Retry Failed Tiles',
          description: 'Retries tiles that failed their HTTP request once',
          value: retryFailedRequestTiles,
          onChanged: (v) => context
              .read<DownloadConfigurationProvider>()
              .retryFailedRequestTiles = v,
        ),
      ],
    );
  }
}

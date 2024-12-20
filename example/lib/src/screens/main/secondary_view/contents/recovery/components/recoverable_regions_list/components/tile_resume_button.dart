part of '../recoverable_regions_list.dart';

class _ResumeButton extends StatelessWidget {
  const _ResumeButton({
    required this.resumeDownload,
  });

  final void Function() resumeDownload;

  @override
  Widget build(BuildContext context) => Selector<DownloadingProvider, bool>(
        selector: (context, provider) => provider.storeName != null,
        builder: (context, isDownloading, _) =>
            Selector<RegionSelectionProvider, bool>(
          selector: (context, provider) =>
              provider.constructedRegions.isNotEmpty,
          builder: (context, isConstructingRegion, _) {
            final cannotResume = isConstructingRegion || isDownloading;

            final button = FilledButton.tonalIcon(
              onPressed: cannotResume ? null : resumeDownload,
              icon: const Icon(Icons.download),
              label: const Text('Resume'),
            );

            if (!cannotResume) return button;

            return Tooltip(
              message: 'Cannot start another download',
              child: button,
            );
          },
        ),
      );
}

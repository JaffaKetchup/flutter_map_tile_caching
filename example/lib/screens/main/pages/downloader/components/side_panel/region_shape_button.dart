part of 'parent.dart';

class _RegionShapeButton extends StatelessWidget {
  const _RegionShapeButton({
    required this.type,
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.tooltip,
  });

  final RegionType type;
  final Icon selectedIcon;
  final Icon unselectedIcon;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Consumer<DownloaderProvider>(
        builder: (context, provider, _) => IconButton(
          icon: unselectedIcon,
          selectedIcon: selectedIcon,
          onPressed: () => provider
            ..regionType = type
            ..clearCoordinates(),
          isSelected: provider.regionType == type,
          tooltip: tooltip,
        ),
      );
}

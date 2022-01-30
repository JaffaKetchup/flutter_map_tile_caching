/*import 'package:flutter/material.dart';
import 'package:fmtc_example/state/bulk_download_provider.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:provider/provider.dart';

class PanelOpts extends StatelessWidget {
  const PanelOpts({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<BulkDownloadProvider>(
      builder: (context, bdp, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNumberSelector(
            value: bdp.minMaxZoom[0],
            min: 1,
            max: 8,
            onChanged: (val) => bdp.minMaxZoom = [val, bdp.minMaxZoom[1]],
            icon: Icons.zoom_out,
          ),
          const Divider(height: 12),
          _buildNumberSelector(
            value: bdp.minMaxZoom[1],
            min: 6,
            max: 16,
            onChanged: (val) => bdp.minMaxZoom = [bdp.minMaxZoom[0], val],
            icon: Icons.zoom_in,
          ),
          const Divider(height: 12),
          _buildNumberSelector(
            value: bdp.parallelThreads,
            min: 1,
            max: 5,
            onChanged: (val) => bdp.parallelThreads = val,
            icon: Icons.format_line_spacing,
          ),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Tooltip(
                child: Icon(Icons.miscellaneous_services),
                message: 'Background Downloading',
              ),
              Switch(
                onChanged: (bool value) => bdp.backgroundDownloading = value,
                value: bdp.backgroundDownloading,
              ),
              const Divider(),
              const Tooltip(
                child: Icon(Icons.refresh),
                message: 'Redownload Tiles',
              ),
              Switch(
                onChanged: (bool value) => bdp.preventRedownload = value,
                value: bdp.preventRedownload,
              ),
              const Divider(),
              const Tooltip(
                child: Icon(Icons.water),
                message: 'Sea Tile Removal',
              ),
              Switch(
                onChanged: (bool value) => bdp.seaTileRemoval = value,
                value: bdp.seaTileRemoval,
              ),
            ],
          ),
          const Divider(height: 12),
        ],
      ),
    );
  }

  Row _buildNumberSelector({
    required int value,
    required int min,
    required int max,
    required void Function(int) onChanged,
    required IconData icon,
  }) {
    return Row(
      children: [
        const Spacer(),
        Icon(icon),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black54),
          ),
          child: NumberPicker(
            value: value,
            minValue: min,
            maxValue: max,
            onChanged: onChanged,
            axis: Axis.horizontal,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.black54),
            ),
            haptics: true,
          ),
        ),
      ],
    );
  }
}
*/
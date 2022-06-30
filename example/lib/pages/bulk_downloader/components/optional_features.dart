import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/bulk_download_provider.dart';

class OptionalFeatures extends StatelessWidget {
  const OptionalFeatures({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<BulkDownloadProvider>(
      builder: (context, bdp, _) {
        return Column(
          children: [
            Row(
              children: [
                const Text('Only Download New Tiles'),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '`preventRedownload` within API. Controls whether the script will re-download tiles that already exist or not.',
                        ),
                        duration: Duration(seconds: 8),
                      ),
                    );
                  },
                  icon: const Icon(Icons.help_outline),
                ),
                Switch(
                  value: bdp.preventRedownload,
                  onChanged: (val) => bdp.preventRedownload = val,
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Remove Sea Tiles'),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '`seaTileRemoval` within API. Deletes tiles that are pure sea - tiles that match the tile at x=0, y=0, z=19 exactly. Note that this saves storage space, but not time or data: tiles still have to be downloaded to be matched. Not supported on satelite servers.',
                        ),
                        duration: Duration(seconds: 8),
                      ),
                    );
                  },
                  icon: const Icon(Icons.help_outline),
                ),
                Switch(
                  value: bdp.seaTileRemoval,
                  onChanged: (val) => bdp.seaTileRemoval = val,
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Disable Recovery (not recommended)'),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Disables automatic recovery. Use only for testing or in special circumstances.',
                        ),
                        duration: Duration(seconds: 8),
                      ),
                    );
                  },
                  icon: const Icon(Icons.help_outline),
                ),
                Switch(
                  value: bdp.disableRecovery,
                  onChanged: (val) => bdp.disableRecovery = val,
                )
              ],
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/state/download_provider.dart';

class OptionalFunctionality extends StatelessWidget {
  const OptionalFunctionality({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('OPTIONAL FUNCTIONALITY'),
          Consumer<DownloadProvider>(
            builder: (context, provider, _) => Column(
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
                      value: provider.preventRedownload,
                      onChanged: (val) => provider.preventRedownload = val,
                      activeColor: Theme.of(context).colorScheme.primary,
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
                      value: provider.seaTileRemoval,
                      onChanged: (val) => provider.seaTileRemoval = val,
                      activeColor: Theme.of(context).colorScheme.primary,
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Disable Recovery'),
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
                      value: provider.disableRecovery,
                      onChanged: (val) async {
                        if (val) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'This option is not recommended, use with caution',
                              ),
                              duration: Duration(seconds: 8),
                            ),
                          );
                        }
                        provider.disableRecovery = val;
                      },
                      activeColor: Colors.amber,
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      );
}

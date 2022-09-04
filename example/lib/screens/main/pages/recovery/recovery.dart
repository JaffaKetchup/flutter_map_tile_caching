import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../../../shared/components/loading_indicator.dart';
import 'components/empty_indicator.dart';
import 'components/header.dart';
import 'components/recovery_list.dart';

class RecoveryPage extends StatefulWidget {
  const RecoveryPage({
    Key? key,
    required this.moveToDownloadPage,
  }) : super(key: key);

  final void Function() moveToDownloadPage;

  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  late Future<List<Future<RecoveredRegion>>> _recoverableRegions;

  @override
  void initState() {
    super.initState();

    void listRecoverableRegions() => _recoverableRegions =
        FMTC.instance.rootDirectory.recovery.recoverableRegions;

    listRecoverableRegions();
    FMTC.instance.rootDirectory.stats.watchChanges(
      rootParts: [RootParts.recovery],
    ).listen((_) {
      if (mounted) {
        listRecoverableRegions();
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Header(),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<List<Future<RecoveredRegion>>>(
                    future: _recoverableRegions,
                    builder: (context, all) => all.hasData
                        ? all.data!.isEmpty
                            ? const EmptyIndicator()
                            : RecoveryList(
                                all: all.data!,
                                moveToDownloadPage: widget.moveToDownloadPage,
                              )
                        : const LoadingIndicator(
                            message: 'Loading Recoverable Downloads...',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

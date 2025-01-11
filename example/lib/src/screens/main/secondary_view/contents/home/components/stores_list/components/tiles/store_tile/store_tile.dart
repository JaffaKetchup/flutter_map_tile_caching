import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../../../../../../../../../../shared/misc/exts/size_formatter.dart';
import '../../../../../../../../../../shared/misc/store_metadata_keys.dart';
import '../../../../../../../../../../shared/state/download_provider.dart';
import '../../../../../../../../../../shared/state/general_provider.dart';
import '../../../../../../../../../store_editor/store_editor.dart';
import 'components/browse_store_strategy_selector/browse_store_strategy_selector.dart';
import 'components/custom_single_slidable_action.dart';

part 'components/trailing.dart';

class StoreTile extends StatefulWidget {
  const StoreTile({
    super.key,
    required this.storeName,
    required this.stats,
    required this.metadata,
    required this.tileImage,
    required this.useCompactLayout,
    this.isFirstStore = false,
  });

  final String storeName;
  final Future<({int hits, int length, int misses, double size})> stats;
  final Future<Map<String, String>> metadata;
  final Future<Image?> tileImage;
  final bool useCompactLayout;
  final bool isFirstStore;

  @override
  State<StoreTile> createState() => _StoreTileState();
}

class _StoreTileState extends State<StoreTile>
    with SingleTickerProviderStateMixin {
  static const _dismissThreshold = 0.25;

  late final _slidableController = SlidableController(this);

  bool _isEmptying = false;

  @override
  void initState() {
    super.initState();

    if (widget.isFirstStore) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Future.delayed(const Duration(seconds: 1), _hintTools),
      );
    }
  }

  @override
  void dispose() {
    _slidableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, outerConstraints) => Slidable(
              key: ValueKey(widget.storeName),
              controller: _slidableController,
              closeOnScroll: false,
              enabled: !_isEmptying,
              startActionPane: ActionPane(
                motion: const BehindMotion(),
                extentRatio: double.minPositive,
                dismissible: DismissiblePane(
                  dismissThreshold: _dismissThreshold,
                  onDismissed: () {},
                  confirmDismiss: () async {
                    unawaited(
                      Navigator.of(context).pushNamed(
                        StoreEditorPopup.route,
                        arguments: widget.storeName,
                      ),
                    );
                    return false;
                  },
                  closeOnCancel: true,
                ),
                children: [
                  CustomSingleSlidableAction(
                    key: ValueKey('${widget.storeName} edit'),
                    unconfirmedIcon: Icons.edit_outlined,
                    confirmedIcon: Icons.edit,
                    color: Colors.blue,
                    alignment: Alignment.centerLeft,
                    dismissThreshold:
                        outerConstraints.maxWidth * _dismissThreshold,
                  ),
                ],
              ),
              endActionPane: ActionPane(
                motion: const BehindMotion(),
                extentRatio: double.minPositive,
                dismissible: DismissiblePane(
                  dismissThreshold: _dismissThreshold,
                  onDismissed: () {},
                  confirmDismiss: () =>
                      _emptyOrDelete(outerConstraints: outerConstraints),
                  closeOnCancel: true,
                ),
                children: [
                  FutureBuilder(
                    future: widget.stats,
                    builder: (context, snapshot) {
                      final length = snapshot.data?.length;
                      if (length == null || length > 0) {
                        return CustomSingleSlidableAction(
                          key: ValueKey('${widget.storeName} empty'),
                          unconfirmedIcon: Icons.layers_clear_outlined,
                          confirmedIcon: Icons.layers_clear,
                          color: Colors.deepOrange,
                          alignment: Alignment.centerRight,
                          dismissThreshold:
                              outerConstraints.maxWidth * _dismissThreshold,
                          showLoader: _isEmptying,
                        );
                      }

                      return CustomSingleSlidableAction(
                        key: ValueKey('${widget.storeName} delete'),
                        unconfirmedIcon: Icons.delete_forever_outlined,
                        confirmedIcon: Icons.delete_forever,
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        dismissThreshold:
                            outerConstraints.maxWidth * _dismissThreshold,
                      );
                    },
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onSecondaryTap: _hintTools,
                  onLongPress: _hintTools,
                  mouseCursor: SystemMouseCursors.basic,
                  child: ListTile(
                    title: Text(
                      widget.storeName,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                    subtitle: FutureBuilder(
                      future: widget.stats,
                      builder: (context, statsSnapshot) {
                        if (statsSnapshot.data case final stats?) {
                          return Text(
                            '${(stats.size * 1024).asReadableSize} | '
                            '${stats.length} tiles',
                          );
                        }
                        return const Text('Loading stats...');
                      },
                    ),
                    leading: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: RepaintBoundary(
                          child: FutureBuilder(
                            future: widget.tileImage,
                            builder: (context, snapshot) {
                              if (snapshot.data case final data?) return data;
                              return const Icon(Icons.filter_none);
                            },
                          ),
                        ),
                      ),
                    ),
                    trailing: FutureBuilder(
                      future: widget.metadata,
                      builder: (context, snapshot) => _Trailing(
                        storeName: widget.storeName,
                        matchesUrl: snapshot.data != null &&
                            context.select<GeneralProvider, String>(
                                  (provider) => provider.urlTemplate,
                                ) ==
                                snapshot
                                    .data![StoreMetadataKeys.urlTemplate.key],
                        useCompactLayout: widget.useCompactLayout,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> _hintTools() async {
    await _slidableController.openTo(
      0,
      curve: Curves.easeOut,
    );
    await _slidableController.openTo(
      -(_dismissThreshold - 0.01),
      curve: Curves.easeOut,
    );
    await Future.delayed(const Duration(milliseconds: 400));
    await _slidableController.openTo(
      0,
      curve: Curves.easeIn,
    );
    await _slidableController.openTo(
      _dismissThreshold - 0.01,
      curve: Curves.easeOut,
    );
    await Future.delayed(const Duration(milliseconds: 400));
    await _slidableController.openTo(
      0,
      curve: Curves.easeIn,
    );
  }

  Future<bool> _emptyOrDelete({
    required BoxConstraints outerConstraints,
  }) async {
    if ((await widget.stats).length == 0) {
      if (!mounted) return false;

      if (context.read<DownloadingProvider>().storeName == widget.storeName) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete store whilst download is in progress'),
          ),
        );
        return false;
      }

      unawaited(
        () async {
          await Future.delayed(const Duration(milliseconds: 500));

          final deletedRecoveryRegions = await FMTCRoot
              .recovery.recoverableRegions
              .then(
                (regions) => regions.failedOnly
                    .where((region) => region.storeName == widget.storeName)
                    .map((region) => region.id),
              )
              .then((ids) => Future.wait(ids.map(FMTCRoot.recovery.cancel)));

          await FMTCStore(widget.storeName).manage.delete();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Deleted ${widget.storeName}'
                '${deletedRecoveryRegions.isEmpty ? '' : ' and associated '
                    'recovery regions'}',
              ),
            ),
          );
        }(),
      );

      return true;
    }

    unawaited(
      _slidableController.openTo(
        -max(
          _dismissThreshold,
          104 / outerConstraints.maxWidth,
        ),
        curve: Curves.easeOut,
      ),
    );

    setState(() => _isEmptying = true);

    await FMTCStore(widget.storeName).manage.reset();

    Future.delayed(
      const Duration(milliseconds: 200),
      () => setState(() => _isEmptying = false),
    );

    return false;
  }
}

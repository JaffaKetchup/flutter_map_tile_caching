import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/state/download_provider.dart';
import '../../../download_region/download_region.dart';
import 'components/header.dart';
import 'components/map_view.dart';

class DownloaderPage extends StatefulWidget {
  const DownloaderPage({Key? key}) : super(key: key);

  @override
  State<DownloaderPage> createState() => _DownloaderPageState();
}

class _DownloaderPageState extends State<DownloaderPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: const [
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Header(),
              ),
            ),
            Expanded(
              child: SizedBox.expand(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: MapView(),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: Consumer<DownloadProvider>(
          builder: (context, provider, _) => FloatingActionButton.extended(
            onPressed: provider.region == null || provider.regionTiles == null
                ? () {}
                : () => Navigator.of(context).push(
                      MaterialPageRoute<String>(
                        builder: (BuildContext context) =>
                            DownloadRegionPopup(region: provider.region!),
                        fullscreenDialog: true,
                      ),
                    ),
            icon: const Icon(Icons.arrow_forward),
            label: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: provider.regionTiles == null
                  ? SizedBox(
                      height: 36,
                      width: 36,
                      child: Center(
                        child: SizedBox(
                          height: 28,
                          width: 28,
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    )
                  : Text('~${provider.regionTiles} tiles'),
            ),
          ),
        ),
      );
}

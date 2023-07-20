import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../shared/state/download_provider.dart';
import 'components/download_layout.dart';

class DownloadingPage extends StatefulWidget {
  const DownloadingPage({super.key});

  @override
  State<DownloadingPage> createState() => _DownloadingPageState();
}

class _DownloadingPageState extends State<DownloadingPage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<DownloadProvider>(
                builder: (context, provider, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Downloading',
                      style: GoogleFonts.openSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      'Downloading To: ${provider.selectedStore!.storeName}',
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Consumer<DownloadProvider>(
                    builder: (context, provider, _) =>
                        StreamBuilder<DownloadProgress>(
                      stream: provider.downloadProgress,
                      builder: (context, snapshot) {
                        if (snapshot.data == null) {
                          return const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  'Taking a while?',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Please wait for the download to start...',
                                ),
                              ],
                            ),
                          );
                        }

                        if (snapshot.data!.latestTileEvent.result.category ==
                            TileEventResultCategory.failed) {
                          provider
                              .addFailedTile(snapshot.data!.latestTileEvent);
                        }

                        return DownloadLayout(
                          storeDirectory: provider.selectedStore!,
                          download: snapshot.data!,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

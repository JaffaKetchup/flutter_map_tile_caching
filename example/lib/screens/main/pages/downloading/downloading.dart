import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import '../../../../shared/state/download_provider.dart';
import 'components/header.dart';
import 'components/horizontal_layout.dart';
import 'components/vertical_layout.dart';

class DownloadingPage extends StatefulWidget {
  const DownloadingPage({Key? key}) : super(key: key);

  @override
  State<DownloadingPage> createState() => _DownloadingPageState();
}

class _DownloadingPageState extends State<DownloadingPage> {
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
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Consumer<DownloadProvider>(
                      builder: (context, provider, _) =>
                          StreamBuilder<DownloadProgress>(
                        stream: provider.downloadProgress,
                        initialData: DownloadProgress.empty(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => provider.setDownloadProgress(
                                null,
                                notify: false,
                              ),
                            );
                          }

                          return LayoutBuilder(
                            builder: (context, constraints) =>
                                constraints.maxWidth > 725
                                    ? HorizontalLayout(data: snapshot.data!)
                                    : VerticalLayout(data: snapshot.data!),
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

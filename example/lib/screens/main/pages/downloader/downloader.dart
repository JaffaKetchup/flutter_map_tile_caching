import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/state/general_provider.dart';
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
        floatingActionButton:
            Provider.of<GeneralProvider>(context).currentStore == null
                ? null
                : FloatingActionButton(
                    onPressed: () {},
                    child: const Icon(Icons.arrow_forward),
                  ),
      );
}

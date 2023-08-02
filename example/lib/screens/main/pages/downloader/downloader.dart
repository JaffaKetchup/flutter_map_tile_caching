import 'package:flutter/material.dart';

import 'components/header.dart';
import 'components/map_view.dart';

class DownloaderPage extends StatefulWidget {
  const DownloaderPage({super.key});

  @override
  State<DownloaderPage> createState() => _DownloaderPageState();
}

class _DownloaderPageState extends State<DownloaderPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: [
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Header(),
              ),
            ),
            Expanded(
              child: SizedBox.expand(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: MediaQuery.of(context).size.width <= 950
                        ? const Radius.circular(20)
                        : Radius.zero,
                  ),
                  child: const MapView(),
                ),
              ),
            ),
          ],
        ),
      );
}

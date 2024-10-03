import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'components/greyscale_masker.dart';

class DownloadProgressMasker extends StatefulWidget {
  const DownloadProgressMasker({
    super.key,
    required this.child,
  });

  final TileLayer child;

  @override
  State<DownloadProgressMasker> createState() => _DownloadProgressMaskerState();
}

class _DownloadProgressMaskerState extends State<DownloadProgressMasker> {
  @override
  Widget build(
          BuildContext
              context) => /* GreyscaleMasker(
        mapCamera: MapCamera.of(context),
        tileMapping: _tileMapping,
        child: widget.child,
      );*/
      Placeholder();
}

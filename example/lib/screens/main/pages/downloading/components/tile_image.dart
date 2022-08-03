import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

Widget tileImage({
  required DownloadProgress data,
  double tileImageSize = 256 / 1.25,
}) =>
    data.tileImage != null
        ? Stack(
            alignment: Alignment.center,
            children: [
              Container(
                foregroundDecoration: BoxDecoration(
                  color: data.percentageProgress != 100
                      ? null
                      : Colors.white.withOpacity(0.75),
                ),
                child: Image(
                  image: data.tileImage!,
                  height: tileImageSize,
                  width: tileImageSize,
                  gaplessPlayback: true,
                ),
              ),
              if (data.percentageProgress == 100)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.done_all,
                      size: 36,
                      color: Colors.green,
                    ),
                    SizedBox(height: 10),
                    Text('Download Complete'),
                  ],
                ),
            ],
          )
        : SizedBox(
            height: tileImageSize,
            width: tileImageSize,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );

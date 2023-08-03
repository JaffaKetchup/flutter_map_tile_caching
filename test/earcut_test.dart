// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

// ignore_for_file: avoid_print

import 'package:flutter_map_tile_caching/src/bulk_download/tile_loops/custom_polygon_tools/earcut.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Simple Triangle',
    () => expect(Earcut.triangulateRaw([0, 0, 0, 50, 50, 00]), [1, 0, 2]),
  );

  test(
    'Complex Triangle',
    () => expect(
      Earcut.triangulateRaw([0, 0, 0, 25, 0, 50, 25, 25, 50, 0, 25, 0]),
      [1, 0, 5, 5, 4, 3, 3, 2, 1, 1, 5, 3],
    ),
  );

  test(
    'L Shape',
    () => expect(
      Earcut.triangulateRaw([0, 0, 10, 0, 10, 5, 5, 5, 5, 15, 0, 15]),
      [4, 5, 0, 0, 1, 2, 3, 4, 0, 0, 2, 3],
    ),
  );

  test(
    'Simple Polygon',
    () => expect(
      Earcut.triangulateRaw([10, 0, 0, 50, 60, 60, 70, 10]),
      [1, 0, 3, 3, 2, 1],
    ),
  );

  test(
    'Polygon With Hole',
    () => expect(
      Earcut.triangulateRaw(
        [0, 0, 100, 0, 100, 100, 0, 100, 20, 20, 80, 20, 80, 80, 20, 80],
        holeIndices: [4],
      ),
      [3, 0, 4, 5, 4, 0, 3, 4, 7, 5, 0, 1, 2, 3, 7, 6, 5, 1, 2, 7, 6, 6, 1, 2],
    ),
  );

  test(
    'Polygon With 3D Coords',
    () => expect(
      Earcut.triangulateRaw(
        [10, 0, 1, 0, 50, 2, 60, 60, 3, 70, 10, 4],
        dimensions: 3,
      ),
      [1, 0, 3, 3, 2, 1],
    ),
  );
}

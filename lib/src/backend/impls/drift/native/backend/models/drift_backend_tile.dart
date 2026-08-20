// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:typed_data';

import '../../../../../interfaces/models.dart';

/// Drift-specific implementation of [BackendTile]
base class DriftBackendTile extends BackendTile {
  /// Create a Drift-specific implementation of [BackendTile]
  DriftBackendTile({
    required this.url,
    required this.bytes,
    required this.lastModified,
  });

  @override
  final String url;

  @override
  final Uint8List bytes;

  @override
  final DateTime lastModified;
}

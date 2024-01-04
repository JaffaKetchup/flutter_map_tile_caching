// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Extension access point for the 'fmtc_plus_sharing' module to add store export
/// functionality
///
/// Does not include any functionality without the module.
class StoreExport {
  const StoreExport._(this.storeDirectory);

  /// Used in the 'fmtc_plus_sharing' module
  ///
  /// Do not use in normal applications.
  @internal
  @protected
  final FMTCStore storeDirectory;
}

// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of flutter_map_tile_caching;

/// Manages a [FMTCRoot]'s representation on the filesystem, such as
/// creation and deletion
class RootManagement {
  const RootManagement._();

  /// Unintialise/close open databases, and delete the root directory and its
  /// contents
  ///
  /// This will remove all traces of this root from the user's device. Use with
  /// caution!
  Future<void> delete() async {
    await FMTCRegistry.instance.uninitialise(delete: true);
    await FMTC.instance.rootDirectory.directory.delete(recursive: true);
    FMTC._instance = null;
  }

  /// Reset the root directory, database, and stores
  ///
  /// Internally calls [delete] then re-initialises FMTC with the same root
  /// directory, [FMTCSettings], and debug mode. Other setup is lost: need to
  /// further customise the [FlutterMapTileCaching.initialise]? Use [delete],
  /// then re-initialise yourself.
  ///
  /// This will remove all traces of this root from the user's device. Use with
  /// caution!
  ///
  /// Returns the new [FlutterMapTileCaching] instance.
  Future<FlutterMapTileCaching> reset() async {
    final directory = FMTC.instance.rootDirectory.directory.absolute.path;
    final settings = FMTC.instance.settings;
    final debugMode = FMTC.instance.debugMode;

    await delete();
    return FMTC.initialise(
      rootDirectory: directory,
      settings: settings,
      debugMode: debugMode,
    );
  }
}

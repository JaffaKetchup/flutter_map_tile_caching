// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

part of '../../flutter_map_tile_caching.dart';

/// Manages a [RootDirectory]'s representation on the filesystem, such as
/// creation and deletion
class RootManagement {
  RootManagement._();

  /// Delete the root directory, database, and stores
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
  /// Internally calls [delete] then re-initialises FMTC with the same setup.
  ///
  /// This will remove all traces of this root from the user's device. Use with
  /// caution!
  Future<void> reset() async {
    final directory = FMTC.instance.rootDirectory.directory.absolute.path;
    final settings = FMTC.instance.settings;

    await delete();
    await FMTC.initialise(
      customRootDirectory: directory,
      customSettings: settings,
    );
  }

  //! DEPRECATED METHODS !//

  /// 'deleteAsync' is deprecated and shouldn't be used. Prefer [delete]. This
  /// redirect will be removed in a future update.
  @Deprecated(
    "Prefer 'delete'. This redirect will be removed in a future update",
  )
  Future<void> deleteAsync() => delete();

  /// 'resetAsync' is deprecated and shouldn't be used. Prefer [reset]. This
  /// redirect will be removed in a future update.
  @Deprecated(
    "Prefer 'reset'. This redirect will be removed in a future update",
  )
  Future<void> resetAsync() => reset();

  /// 'create' is deprecated and shouldn't be used. Creation is now performed
  /// automatically when initialising FMTC. This remnant will be removed in a
  /// future update.
  @Deprecated(
    'Creation is now performed automatically when initialising FMTC. This remnant will be removed in a future update',
  )
  @alwaysThrows
  Never create() => throw UnsupportedError(
        "'create' is deprecated and shouldn't be used. Creation is now performed automatically when initialising FMTC. This remnant will be removed in a future update.",
      );

  /// 'createAsync' is deprecated and shouldn't be used. Creation is now
  /// performed automatically when initialising FMTC. This remnant will be
  /// removed in a future update.
  @Deprecated(
    'Creation is now performed automatically when initialising FMTC. This remnant will be removed in a future update',
  )
  @alwaysThrows
  Future<Never> createAsync() async => throw UnsupportedError(
        "'createAsync' is deprecated and shouldn't be used. Creation is now performed automatically when initialising FMTC. This remnant will be removed in a future update.",
      );

  /// 'ready' is deprecated and shouldn't be used. Assume that the necessary
  /// directories and files exist after initialisation and until 'delete' is
  /// used. This remnant will be removed in a future update.
  @Deprecated(
    "Assume that the necessary directories and files exist after initialisation and until 'delete' is used",
  )
  @alwaysThrows
  Never get ready => throw UnsupportedError(
        "'ready' is deprecated and shouldn't be used. Assume that the necessary directories and files exist after initialisation and until 'delete' is used. This remnant will be removed in a future update.",
      );

  /// 'readyAsync' is deprecated and shouldn't be used. Assume that the necessary
  /// directories and files exist after initialisation and until 'delete' is
  /// used. This remnant will be removed in a future update.
  @Deprecated(
    "Assume that the necessary directories and files exist after initialisation and until 'delete' is used",
  )
  @alwaysThrows
  Future<Never> get readyAsync async => throw UnsupportedError(
        "'readyAsync' is deprecated and shouldn't be used. Assume that the necessary directories and files exist after initialisation and until 'delete' is used. This remnant will be removed in a future update.",
      );
}

import 'dart:typed_data';

import '../interfaces/backend.dart';
import 'errors.dart';

/// A shortcut to declare that an [FMTCBackend] does not support any synchronous
/// versions of methods
mixin FMTCBackendNoSync implements FMTCBackend {
  /// This synchronous method is unsupported by this implementation - use
  /// [initialise] instead
  @override
  Never initialiseSync({
    String? rootDirectory,
    int? maxDatabaseSize,
    Map<String, Object> implSpecificArgs = const {},
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncInitialise = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [destroy] instead
  @override
  Never destroySync({
    bool deleteRoot = false,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncDestroy = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [createStore] instead
  @override
  Never createStoreSync({
    required String storeName,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncCreateStore = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [resetStore] instead
  @override
  Never resetStoreSync({
    required String storeName,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncResetStore = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [renameStore] instead
  @override
  Never renameStoreSync({
    required String currentStoreName,
    required String newStoreName,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncRenameStore = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [deleteStore] instead
  @override
  Never deleteStoreSync({
    required String storeName,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncDeleteStore = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [getStoreSize] instead
  @override
  Never getStoreSizeSync({
    required String storeName,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncGetStoreSize = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [getStoreLength] instead
  @override
  Never getStoreLengthSync({
    required String storeName,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncGetStoreLength = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [readTile] instead
  @override
  Never readTileSync({
    required String url,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncReadTile = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [writeTile] instead
  @override
  Never writeTileSync({
    required String storeName,
    required String url,
    required Uint8List? bytes,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncWriteTile = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [deleteTile] instead
  @override
  Never deleteTileSync({
    required String storeName,
    required String url,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncDeleteTile = false;
}

import 'dart:typed_data';

import '../interfaces/backend.dart';
import '../interfaces/models.dart';
import 'errors.dart';

/// A shortcut to declare that an [FMTCBackend] does not support any synchronous
/// versions of methods
mixin FMTCBackendNoSync implements FMTCBackendInternal {
  /// This synchronous method is unsupported by this implementation - use
  /// [initialise] instead
  @override
  void initialiseSync({
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
  void destroySync({
    bool deleteRoot = false,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncDestroy = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [createStore] instead
  @override
  void createStoreSync({
    required String storeName,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncCreateStore = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [resetStore] instead
  @override
  void resetStoreSync({
    required String storeName,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncResetStore = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [renameStore] instead
  @override
  void renameStoreSync({
    required String currentStoreName,
    required String newStoreName,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncRenameStore = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [deleteStore] instead
  @override
  void deleteStoreSync({
    required String storeName,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncDeleteStore = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [getStoreSize] instead
  @override
  double getStoreSizeSync({
    required String storeName,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncGetStoreSize = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [getStoreLength] instead
  @override
  int getStoreLengthSync({
    required String storeName,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncGetStoreLength = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [getStoreHits] instead
  @override
  int getStoreHitsSync({
    required String storeName,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncGetStoreHits = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [getStoreMisses] instead
  @override
  int getStoreMissesSync({
    required String storeName,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncGetStoreMisses = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [readTile] instead
  @override
  BackendTile? readTileSync({
    required String url,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncReadTile = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [writeTile] instead
  @override
  void writeTileSync({
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
  bool? deleteTileSync({
    required String storeName,
    required String url,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncDeleteTile = false;

  /// This synchronous method is unsupported by this implementation - use
  /// [removeOldestTile] instead
  @override
  void removeOldestTileSync({
    required String storeName,
  }) =>
      throw SyncOperationUnsupported();

  @override
  final supportsSyncRemoveOldestTile = false;
}

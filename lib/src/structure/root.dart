import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'store.dart';

/// Manages the directory beneath which 'flutter_map_tile_caching' places all data, such as multiple [StoreDirectory]s
///
/// Usually only one of these should exist per application (representing one real directory), but multiple can be used if necessary
class RootDirectory {
  //! PROPS & CONSTRUCTORS !//

  /// The real directory beneath which 'flutter_map_tile_caching' places all data - usually located itself within the application's directories
  final Directory rootDirectory;

  /// Create a [RootDirectory] set based on your own custom directory
  ///
  /// This should only be used under special circumstances. Ensure that your application has full access to the directory, or permission errors will occur.
  ///
  /// Construction via this method automatically calls [initialise] before returning (by default), so the caching directories will exist unless deleted using [clean]. Disable this initialisation by setting [autoInitialise] to `false`.
  RootDirectory.custom(this.rootDirectory, {bool autoInitialise = true}) {
    if (autoInitialise) initialise();
  }

  /// Create a [RootDirectory] set based on the app's documents directory
  ///
  /// This is the recommended base, as the directory cannot be cleared by the OS without warning. To completely clear this directory, the user must manually clear ALL app data, not just app cache.
  ///
  /// Construction via this method automatically calls [initialiseAsync] before returning, so the caching directories will exist unless deleted using [clean].
  static Future<RootDirectory> get normalCache async {
    final RootDirectory returnable = RootDirectory.custom(
      await getApplicationDocumentsDirectory(),
      autoInitialise: false,
    );
    await returnable.initialiseAsync();
    return returnable;
  }

  /// Create a [RootDirectory] set based on the app's temporary directory
  ///
  /// This should only be used when requested by a user, as the directory can be cleared by the OS without warning.
  ///
  /// Construction via this method automatically calls [initialiseAsync] before returning, so the caching directories will exist unless deleted using [clean].
  static Future<RootDirectory> get temporaryCache async {
    final RootDirectory returnable = RootDirectory.custom(
      await getTemporaryDirectory(),
      autoInitialise: false,
    );
    await returnable.initialiseAsync();
    return returnable;
  }

  //! MANAGEMENT !//

  /// Get the absolute path to the root directory
  String get path => rootDirectory.absolute.path;

  /// Check whether the root exists synchronously
  bool get ready => rootDirectory.existsSync();

  /// Check whether the root exists asynchronously
  Future<bool> get readyAsync => rootDirectory.exists();

  /// Create the root directory synchronously
  void initialise() => rootDirectory.createSync(recursive: true);

  /// Create the root directory asynchronously
  Future<void> initialiseAsync() => rootDirectory.create(recursive: true);

  /// Delete the root directory synchronously
  ///
  /// This will erase all traces of 'flutter_map_tile_caching' from the user's device. Use with caution!
  void clean() => rootDirectory.deleteSync(recursive: true);

  /// Delete the root directory asynchronously
  ///
  /// This will erase all traces of 'flutter_map_tile_caching' from the user's device. Use with caution!
  Future<void> cleanAsync() => rootDirectory.delete(recursive: true);
}

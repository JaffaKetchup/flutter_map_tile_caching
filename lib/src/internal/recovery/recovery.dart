import 'dart:io';

import '../../regions/downloadable_region.dart';
import '../../regions/recovered_region.dart';
import '../exts.dart';
import '../store.dart';
import 'end.dart';
import 'read.dart';
import 'start.dart';

/// Used internally to manage bulk download recovery
class Recovery {
  /// The file used to store information used when recovering a download
  final File recoveryFile;

  /// Used internally to manage bulk download recovery
  Recovery(StoreDirectory storeDirectory)
      : recoveryFile = storeDirectory.access.metadata >>>
            '${DateTime.now().millisecondsSinceEpoch.toString()}.recovery.ini';

  /// Start the recovery - create and configure the file
  ///
  /// [identification] should be a human-readable description of the download that the recovery file is attached to
  Future<void> startRecovery(
          DownloadableRegion region, String identification) =>
      start(recoveryFile, region, identification);

  /// End the recovery - delete the file
  Future<void> endRecovery() => end(recoveryFile);

  /// Recover the information - read the file
  Future<RecoveredRegion?> readRecovery() => read(recoveryFile);
}

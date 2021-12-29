import 'dart:io';

import 'package:path/path.dart' as p show joinAll;

import '../../regions/downloadable_region.dart';
import '../../regions/recovered_region.dart';
import 'end.dart';
import 'read.dart';
import 'start.dart';

/// Used internally to manage bulk download recovery
class Recovery {
  /// The file used to store information used when recovering a download
  final File recoveryFile;

  /// Used internally to manage bulk download recovery
  Recovery(String storePath)
      : recoveryFile = File(p.joinAll([storePath, 'fmtcDownload.recovery']));

  /// Start the recovery - create and configure the file
  Future<void> startRecovery(DownloadableRegion region) =>
      start(recoveryFile, region);

  /// End the recovery - delete the file
  Future<void> endRecovery() => end(recoveryFile);

  /// Recover the information - read the file
  Future<RecoveredRegion?> readRecovery() => read(recoveryFile);
}

import '../bulk_download/download_progress.dart';
import '../misc/exts.dart';

String replacePlaceholdersNotificationText({
  required String textWithPlaceholders,
  required DownloadProgress downloadProgress,
}) =>
    textWithPlaceholders
        .replaceAll(
          '{attemptedTiles}',
          downloadProgress.attemptedTiles.toString(),
        )
        .replaceAll(
          '{duration}',
          downloadProgress.duration.formatted,
        )
        .replaceAll(
          '{estRemainingDuration}',
          downloadProgress.estRemainingDuration.formatted,
        )
        .replaceAll(
          '{estTotalDuration}',
          downloadProgress.estTotalDuration.formatted,
        )
        .replaceAll(
          '{existingTiles}',
          downloadProgress.existingTiles.toString(),
        )
        .replaceAll(
          '{existingTilesDiscount}',
          downloadProgress.existingTilesDiscount.toStringAsFixed(2),
        )
        .replaceAll(
          '{failedTiles}',
          downloadProgress.failedTiles.toString(),
        )
        .replaceAll(
          '{maxTiles}',
          downloadProgress.maxTiles.toString(),
        )
        .replaceAll(
          '{percentageProgress}',
          downloadProgress.percentageProgress.toStringAsFixed(2),
        )
        .replaceAll(
          '{remainingTiles}',
          downloadProgress.remainingTiles.toString(),
        )
        .replaceAll(
          '{seaTiles}',
          downloadProgress.seaTiles.toString(),
        )
        .replaceAll(
          '{seaTilesDiscount}',
          downloadProgress.seaTilesDiscount.toStringAsFixed(2),
        )
        .replaceAll(
          '{successfulTiles}',
          downloadProgress.successfulTiles.toString(),
        );

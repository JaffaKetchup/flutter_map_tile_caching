// ignore_for_file: avoid_print
// TODO: Remove prints

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../bulk_download/download_progress.dart';

class FMTCBackgroundTaskHandler extends TaskHandler {
  FMTCBackgroundTaskHandler(//{
      //this.updateNotificationTitle,
      //this.updateNotificationTextBuilder,
      //this.launchAppRoute,
      /*}*/);

  //final String? updateNotificationTitle;
  //final String? Function(String)? updateNotificationTextBuilder;
  //final String? launchAppRoute;

  SendPort? _sendPort;
  int _eventCount = 0;

  String? notificationTitle;
  String? notificationText;

  String _replacePlaceholdersNotificationText({
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
            downloadProgress.duration
                .toString()
                .split('.')
                .first
                .padLeft(8, '0'),
          )
          .replaceAll(
            '{estRemainingDuration}',
            downloadProgress.estRemainingDuration
                .toString()
                .split('.')
                .first
                .padLeft(8, '0'),
          )
          .replaceAll(
            '{estTotalDuration}',
            downloadProgress.estTotalDuration
                .toString()
                .split('.')
                .first
                .padLeft(8, '0'),
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

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    notificationTitle =
        await FlutterForegroundTask.getData<String?>(key: 'notificationTitle');
    print('notificationTitle: $notificationTitle');

    notificationText =
        await FlutterForegroundTask.getData<String?>(key: 'notificationText');
    print('notificationText: $notificationText');

    print(
      'formatted: ' +
          _replacePlaceholdersNotificationText(
            textWithPlaceholders: notificationText!,
            downloadProgress: DownloadProgress.empty(),
          ),
    );
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    unawaited(
      FlutterForegroundTask.updateService(
        notificationTitle: notificationTitle == null
            ? 'Downloading Map Tiles'
            : _replacePlaceholdersNotificationText(
                textWithPlaceholders: notificationTitle!,
                downloadProgress: DownloadProgress.empty(),
              ),
        notificationText: notificationText == null
            ? 'Please wait... ($_eventCount)'
            : _replacePlaceholdersNotificationText(
                textWithPlaceholders: notificationText!,
                downloadProgress: DownloadProgress.empty(),
              ),
      ),
    );

    // Send data to the main isolate.
    sendPort?.send(_eventCount);

    _eventCount++;
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // You can use the clearAllData function to clear all the stored data.
    await FlutterForegroundTask.clearAllData();
  }

  @override
  void onButtonPressed(String id) {
    // Called when the notification button on the Android platform is pressed.
    print('onButtonPressed >> $id');
  }

  @override
  void onNotificationPressed() {
    // Called when the notification itself on the Android platform is pressed.
    //
    // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
    // this function to be called.

    // Note that the app will only route to "/resume-route" when it is exited so
    // it will usually be necessary to send a message through the send port to
    // signal it to restore state when the app is already started.
    FlutterForegroundTask.launchApp('/');
    _sendPort?.send('onNotificationPressed');
  }
}

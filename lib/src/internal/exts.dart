// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:path/path.dart' as p;

extension DirectoryExtensions on Directory {
  String operator >(String sub) => p.join(
        absolute.path,
        sub,
      );

  Directory operator >>(String sub) => Directory(
        p.join(
          absolute.path,
          sub,
        ),
      );

  File operator >>>(String name) => File(
        p.join(
          absolute.path,
          name,
        ),
      );

  /// A safer version of [exists], but checks that the directory exists before listing it's contents
  ///
  /// Returns same result as [list] in future.
  Future<Stream<FileSystemEntity>> listWithExists({
    bool recursive = false,
    bool followLinks = true,
  }) async {
    if (!await exists()) return const Stream.empty();
    return list(
      recursive: recursive,
      followLinks: followLinks,
    );
  }
}

extension IterableNumExts on Iterable<num> {
  num get sum => reduce((v, e) => v + e);
}

extension AndroidNotificationDetailsExts on AndroidNotificationDetails {
  AndroidNotificationDetails copyWith({
    String? icon,
    String? channelId,
    String? channelName,
    String? channelDescription,
    bool? channelShowBadge,
    Importance? importance,
    Priority? priority,
    bool? playSound,
    AndroidNotificationSound? sound,
    bool? enableVibration,
    bool? enableLights,
    Int64List? vibrationPattern,
    StyleInformation? styleInformation,
    String? groupKey,
    bool? setAsGroupSummary,
    GroupAlertBehavior? groupAlertBehavior,
    bool? autoCancel,
    bool? ongoing,
    Color? color,
    AndroidBitmap<Object>? largeIcon,
    bool? onlyAlertOnce,
    bool? showWhen,
    int? when,
    bool? usesChronometer,
    bool? showProgress,
    int? maxProgress,
    int? progress,
    bool? indeterminate,
    Color? ledColor,
    int? ledOnMs,
    int? ledOffMs,
    String? ticker,
    AndroidNotificationChannelAction? channelAction,
    NotificationVisibility? visibility,
    int? timeoutAfter,
    AndroidNotificationCategory? category,
    bool? fullScreenIntent,
    String? shortcutId,
    Int32List? additionalFlags,
    String? subText,
    String? tag,
    bool? colorized,
    int? number,
  }) =>
      AndroidNotificationDetails(
        channelId ?? this.channelId,
        channelName ?? this.channelName,
        channelDescription: channelDescription ?? this.channelDescription,
        icon: icon ?? this.icon,
        channelShowBadge: channelShowBadge ?? this.channelShowBadge,
        importance: importance ?? this.importance,
        priority: priority ?? this.priority,
        playSound: playSound ?? this.playSound,
        sound: sound ?? this.sound,
        enableVibration: enableVibration ?? this.enableVibration,
        enableLights: enableLights ?? this.enableLights,
        vibrationPattern: vibrationPattern ?? this.vibrationPattern,
        styleInformation: styleInformation ?? this.styleInformation,
        groupKey: groupKey ?? this.groupKey,
        setAsGroupSummary: setAsGroupSummary ?? this.setAsGroupSummary,
        groupAlertBehavior: groupAlertBehavior ?? this.groupAlertBehavior,
        autoCancel: autoCancel ?? this.autoCancel,
        ongoing: ongoing ?? this.ongoing,
        color: color ?? this.color,
        largeIcon: largeIcon ?? this.largeIcon,
        onlyAlertOnce: onlyAlertOnce ?? this.onlyAlertOnce,
        showWhen: showWhen ?? this.showWhen,
        when: when ?? this.when,
        usesChronometer: usesChronometer ?? this.usesChronometer,
        showProgress: showProgress ?? this.showProgress,
        maxProgress: maxProgress ?? this.maxProgress,
        progress: progress ?? this.progress,
        indeterminate: indeterminate ?? this.indeterminate,
        ledColor: ledColor ?? this.ledColor,
        ledOnMs: ledOnMs ?? this.ledOnMs,
        ledOffMs: ledOffMs ?? this.ledOffMs,
        ticker: ticker ?? this.ticker,
        channelAction: channelAction ?? this.channelAction,
        visibility: visibility ?? this.visibility,
        timeoutAfter: timeoutAfter ?? this.timeoutAfter,
        category: category ?? this.category,
        fullScreenIntent: fullScreenIntent ?? this.fullScreenIntent,
        shortcutId: shortcutId ?? this.shortcutId,
        additionalFlags: additionalFlags ?? this.additionalFlags,
        subText: subText ?? this.subText,
        tag: tag ?? this.tag,
        colorized: colorized ?? this.colorized,
        number: number ?? this.number,
      );
}

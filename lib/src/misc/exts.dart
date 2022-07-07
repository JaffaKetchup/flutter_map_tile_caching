import 'package:flutter_foreground_task/flutter_foreground_task.dart';

extension AndroidNotificationOptionsExts on AndroidNotificationOptions {
  AndroidNotificationOptions copyWith({
    String? channelId,
    String? channelName,
    String? channelDescription,
    NotificationChannelImportance? channelImportance,
    NotificationPriority? priority,
    bool? enableVibration,
    bool? playSound,
    bool? showWhen,
    bool? isSticky,
    NotificationVisibility? visibility,
    NotificationIconData? iconData,
    List<NotificationButton>? buttons,
  }) =>
      AndroidNotificationOptions(
        channelId: channelId ?? this.channelId,
        channelName: channelName ?? this.channelName,
        channelDescription: channelDescription ?? this.channelDescription,
        channelImportance: channelImportance ?? this.channelImportance,
        priority: priority ?? this.priority,
        enableVibration: enableVibration ?? this.enableVibration,
        playSound: playSound ?? this.playSound,
        showWhen: showWhen ?? this.showWhen,
        isSticky: isSticky ?? this.isSticky,
        visibility: visibility ?? this.visibility,
        iconData: iconData ?? this.iconData,
        buttons: buttons ?? this.buttons,
      );
}

extension IOSNotificationOptionsExts on IOSNotificationOptions {
  IOSNotificationOptions copyWith({
    bool? showNotification,
    bool? playSound,
  }) =>
      IOSNotificationOptions(
        showNotification: showNotification ?? this.showNotification,
        playSound: playSound ?? this.playSound,
      );
}

extension DurationExts on Duration {
  String get formatted => toString().split('.').first.padLeft(8, '0');
}

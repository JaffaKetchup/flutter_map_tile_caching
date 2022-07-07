import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// A widget that enables correct functioning of the background download process/service
///
/// This widget is only necessary if your application provides background downloading. It prevents the application from fully closing when the process is running.
///
/// This widget should be wrapped around the root level `Scaffold` widget (become it's parent). There is no useful effect if this widget is used lower down in the widget tree.
typedef FMTCBackgroundDownload = WithForegroundTask;

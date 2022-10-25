// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:flutter/widgets.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:move_to_background/move_to_background.dart';

/// A widget that enables correct functioning of the background download process/service
///
/// This widget is only necessary if your application provides background downloading. It prevents the application from fully closing when the process is running.
///
/// This widget should be wrapped around the root level `Scaffold` widget (become it's parent). There is no useful effect if this widget is used lower down in the widget tree.
class FMTCBackgroundDownload extends StatefulWidget {
  /// A child widget, usually containing a `Scaffold` widget and the rest of the application UI
  final Widget child;

  /// A widget that enables correct functioning of the background download process/service
  ///
  /// This widget is only necessary if your application provides background downloading. It prevents the application from fully closing when the process is running.
  ///
  /// This widget should be wrapped around the root level `Scaffold` widget (become it's parent). There is no useful effect if this widget is used lower down in the widget tree.
  const FMTCBackgroundDownload({
    super.key,
    required this.child,
  });

  @override
  State<StatefulWidget> createState() => _FMTCBackgroundDownloadState();
}

class _FMTCBackgroundDownloadState extends State<FMTCBackgroundDownload> {
  Future<bool> _onWillPop() async {
    if (!Navigator.canPop(context) &&
        FlutterBackground.isBackgroundExecutionEnabled) {
      await MoveToBackground.moveTaskToBack();
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) =>
      WillPopScope(onWillPop: _onWillPop, child: widget.child);
}

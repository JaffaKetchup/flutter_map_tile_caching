import 'package:flutter/widgets.dart';

class BottomSheetScrollableProvider extends InheritedWidget {
  const BottomSheetScrollableProvider({
    super.key,
    required super.child,
    required this.innerScrollController,
  });

  final ScrollController innerScrollController;

  Widget build(BuildContext context) => child;

  static ScrollController innerScrollControllerOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BottomSheetScrollableProvider>()!
          .innerScrollController;

  @override
  bool updateShouldNotify(covariant BottomSheetScrollableProvider oldWidget) =>
      oldWidget.innerScrollController != innerScrollController;
}

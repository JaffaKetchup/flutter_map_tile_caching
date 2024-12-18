import 'package:flutter/widgets.dart';

class BottomSheetScrollableProvider extends InheritedWidget {
  const BottomSheetScrollableProvider({
    super.key,
    required super.child,
    required this.innerScrollController,
    required this.outerScrollController,
  });

  final ScrollController innerScrollController;
  final DraggableScrollableController outerScrollController;

  Widget build(BuildContext context) => child;

  static ScrollController innerScrollControllerOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BottomSheetScrollableProvider>()!
          .innerScrollController;

  static DraggableScrollableController? maybeOuterScrollControllerOf(
    BuildContext context,
  ) =>
      context
          .dependOnInheritedWidgetOfExactType<BottomSheetScrollableProvider>()
          ?.outerScrollController;

  static DraggableScrollableController outerScrollControllerOf(
    BuildContext context,
  ) =>
      maybeOuterScrollControllerOf(context)!;

  @override
  bool updateShouldNotify(covariant BottomSheetScrollableProvider oldWidget) =>
      oldWidget.innerScrollController != innerScrollController ||
      oldWidget.outerScrollController != outerScrollController;
}

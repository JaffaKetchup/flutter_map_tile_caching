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

  static ScrollController? maybeInnerScrollControllerOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BottomSheetScrollableProvider>()
          ?.innerScrollController;

  static ScrollController innerScrollControllerOf(BuildContext context) =>
      maybeInnerScrollControllerOf(context)!;

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
      oldWidget.innerScrollController != innerScrollController;
}

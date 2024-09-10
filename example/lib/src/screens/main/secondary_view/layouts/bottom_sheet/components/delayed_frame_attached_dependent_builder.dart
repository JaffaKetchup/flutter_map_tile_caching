import 'package:flutter/material.dart';

/// Builds [builder] whenever [listenable] fires a notififcation, but also
/// rebuilds [builder] after at least one frame, to allow [listenable] (which is
/// usually some type of controller) to attach itself to a widget elsewhere in
/// the tree
///
/// [builder] must not assume [listenable] is attached. The purpose of this
/// widget is not to remove the requirement for an initial value (which is
/// extremely difficult/impossible), but to eliminate the unnnecessary frame lag
/// after attachment.
class DelayedControllerAttachmentBuilder extends StatefulWidget {
  const DelayedControllerAttachmentBuilder({
    super.key,
    required this.listenable,
    required this.builder,
    this.child,
  });

  final Listenable listenable;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  @override
  State<DelayedControllerAttachmentBuilder> createState() =>
      _DelayedControllerAttachmentBuilderState();
}

class _DelayedControllerAttachmentBuilderState
    extends State<DelayedControllerAttachmentBuilder> {
  // When used in combination with `FutureBuilder`, which can build at most
  // once per frame, this means the future completes in the next microtask,
  // which is at least the next frame.
  //
  // The listenable (which is a controller) should attach itself to whatever is
  // required by this point, as that should take at most one frame.
  final delayFrameFuture = Future.microtask(() => null);

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: delayFrameFuture,
        builder: (context, _) => AnimatedBuilder(
          animation: widget.listenable,
          builder: widget.builder,
          child: widget.child,
        ),
      );
}

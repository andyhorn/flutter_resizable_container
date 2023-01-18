import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ResizeCursor extends StatefulWidget {
  const ResizeCursor({
    super.key,
    required this.direction,
    required this.onResizeUpdate,
  });

  final Axis direction;
  final void Function(double) onResizeUpdate;

  @override
  State<ResizeCursor> createState() => _ResizeCursorState();
}

class _ResizeCursorState extends State<ResizeCursor> {
  bool isGrabbing = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.direction == Axis.horizontal
          ? Alignment.centerRight
          : Alignment.bottomCenter,
      child: MouseRegion(
        cursor:
            isGrabbing ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        child: GestureDetector(
          onVerticalDragStart: _startGrab,
          onVerticalDragEnd: _endGrab,
          onVerticalDragCancel: _cancelGrab,
          onHorizontalDragStart: _startGrab,
          onHorizontalDragEnd: _endGrab,
          onHorizontalDragCancel: _cancelGrab,
          onTapUp: (_) => setState(() => isGrabbing = false),
          onVerticalDragUpdate: widget.direction == Axis.vertical
              ? (details) => widget.onResizeUpdate(details.delta.dy)
              : null,
          onHorizontalDragUpdate: widget.direction == Axis.horizontal
              ? (details) => widget.onResizeUpdate(details.delta.dx)
              : null,
          child: widget.direction == Axis.horizontal
              ? const Icon(MdiIcons.drag)
              : const Icon(MdiIcons.dragHorizontal),
        ),
      ),
    );
  }

  void _startGrab(DragStartDetails _) => _setGrabbing(true);

  void _endGrab(DragEndDetails _) => _setGrabbing(false);

  void _cancelGrab() => _setGrabbing(false);

  void _setGrabbing(bool grabbing) => setState(() => isGrabbing = grabbing);
}

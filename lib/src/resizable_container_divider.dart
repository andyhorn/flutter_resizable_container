import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/src/divider_painter.dart';

class ResizableContainerDivider extends StatelessWidget {
  const ResizableContainerDivider({
    super.key,
    required this.direction,
    required this.onResizeUpdate,
    required this.dividerWidth,
    required this.dividerColor,
    this.indent,
    this.endIndent,
  });

  final Axis direction;
  final void Function(double) onResizeUpdate;
  final double dividerWidth;
  final Color dividerColor;
  final double? indent;
  final double? endIndent;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _getCursor(),
      child: GestureDetector(
        onVerticalDragUpdate: direction == Axis.vertical
            ? (details) => onResizeUpdate(details.delta.dy)
            : null,
        onHorizontalDragUpdate: direction == Axis.horizontal
            ? (details) => onResizeUpdate(details.delta.dx)
            : null,
        child: SizedBox(
          height: direction == Axis.horizontal ? double.infinity : dividerWidth,
          width: direction == Axis.horizontal ? dividerWidth : double.infinity,
          child: CustomPaint(
            painter: DividerPainter(
              direction: direction,
              width: dividerWidth,
              color: dividerColor,
              indent: indent,
              endIndent: endIndent,
            ),
          ),
        ),
      ),
    );
  }

  MouseCursor _getCursor() {
    switch (direction) {
      case Axis.horizontal:
        return SystemMouseCursors.resizeLeftRight;
      case Axis.vertical:
        return SystemMouseCursors.resizeUpDown;
    }
  }
}

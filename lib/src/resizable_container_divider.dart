import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/src/divider_painter.dart';
import 'package:flutter_resizable_container/src/resizable_divider.dart';

class ResizableContainerDivider extends StatelessWidget {
  const ResizableContainerDivider({
    super.key,
    required this.direction,
    required this.onResizeUpdate,
    required this.config,
  });

  final Axis direction;
  final void Function(double) onResizeUpdate;
  final ResizableDivider config;

  double get height =>
      direction == Axis.horizontal ? double.infinity : config.height;
  double get width =>
      direction == Axis.horizontal ? config.height : double.infinity;

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
          height: height,
          width: width,
          child: Center(
            child: CustomPaint(
              size: Size(width, height),
              painter: DividerPainter(
                direction: direction,
                color: config.color ?? Theme.of(context).dividerColor,
                thickness: config.thickness,
                indent: config.indent,
                endIndent: config.endIndent,
              ),
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

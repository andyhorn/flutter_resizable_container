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

  @override
  Widget build(BuildContext context) {
    final width = _getWidth();
    final height = _getHeight();

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
    return switch (direction) {
      Axis.horizontal => SystemMouseCursors.resizeLeftRight,
      Axis.vertical => SystemMouseCursors.resizeUpDown,
    };
  }

  double _getHeight() {
    return switch (direction) {
      Axis.horizontal => double.infinity,
      Axis.vertical => config.height,
    };
  }

  double _getWidth() {
    return switch (direction) {
      Axis.horizontal => config.height,
      Axis.vertical => double.infinity,
    };
  }
}

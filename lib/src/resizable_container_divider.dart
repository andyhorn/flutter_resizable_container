import 'package:flutter/material.dart';

class ResizableContainerDivider extends StatelessWidget {
  const ResizableContainerDivider({
    super.key,
    required this.direction,
    required this.onResizeUpdate,
    required this.dividerWidth,
    required this.dividerColor,
  });

  final Axis direction;
  final void Function(double) onResizeUpdate;
  final double dividerWidth;
  final Color dividerColor;

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
        child: _Divider(
          direction: direction,
          width: dividerWidth,
          color: dividerColor,
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

class _Divider extends StatelessWidget {
  const _Divider({
    required this.color,
    required this.direction,
    required this.width,
  });

  final Axis direction;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: direction == Axis.horizontal ? double.infinity : width,
      width: direction == Axis.horizontal ? width : double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
        ),
      ),
    );
  }
}

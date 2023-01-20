import 'package:flutter/material.dart';

class ResizableContainerDivider extends StatelessWidget {
  const ResizableContainerDivider({
    super.key,
    required this.direction,
    required this.onResizeUpdate,
  });

  final Axis direction;
  final void Function(double) onResizeUpdate;

  static const dividerWidth = 2.5;

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
    required this.direction,
  });

  final Axis direction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: direction == Axis.horizontal
          ? double.infinity
          : ResizableContainerDivider.dividerWidth,
      width: direction == Axis.horizontal
          ? ResizableContainerDivider.dividerWidth
          : double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor,
        ),
      ),
    );
  }
}

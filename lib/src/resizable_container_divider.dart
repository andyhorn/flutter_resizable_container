import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_resizable_container/src/divider_painter.dart';
import 'package:flutter_resizable_container/src/resizable_divider.dart';

class ResizableContainerDivider extends StatefulWidget {
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
  State<ResizableContainerDivider> createState() =>
      _ResizableContainerDividerState();
}

class _ResizableContainerDividerState extends State<ResizableContainerDivider> {
  bool isDragging = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final width = _getWidth();
    final height = _getHeight();

    return MouseRegion(
      cursor: _getCursor(),
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: SizedBox(
          height: height,
          width: width,
          child: Center(
            child: CustomPaint(
              size: Size(width, height),
              painter: DividerPainter(
                direction: widget.direction,
                color: widget.config.color ?? Theme.of(context).dividerColor,
                thickness: widget.config.thickness,
                indent: widget.config.indent,
                endIndent: widget.config.endIndent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  MouseCursor _getCursor() {
    return switch (widget.direction) {
      Axis.horizontal => SystemMouseCursors.resizeLeftRight,
      Axis.vertical => SystemMouseCursors.resizeUpDown,
    };
  }

  double _getHeight() {
    return switch (widget.direction) {
      Axis.horizontal => double.infinity,
      Axis.vertical => widget.config.size,
    };
  }

  double _getWidth() {
    return switch (widget.direction) {
      Axis.horizontal => widget.config.size,
      Axis.vertical => double.infinity,
    };
  }

  void _onEnter(PointerEnterEvent _) {
    setState(() => isHovered = false);
    widget.config.onHoverEnter?.call();
  }

  void _onExit(PointerExitEvent _) {
    setState(() => isHovered = false);

    if (!isDragging) {
      widget.config.onHoverExit?.call();
    }
  }

  void _onVerticalDragStart(DragStartDetails _) {
    if (widget.direction == Axis.vertical) {
      setState(() => isDragging = true);
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (widget.direction == Axis.vertical) {
      widget.onResizeUpdate(details.delta.dy);
    }
  }

  void _onVerticalDragEnd(DragEndDetails _) {
    if (widget.direction == Axis.vertical) {
      setState(() => isDragging = false);

      if (!isHovered) {
        widget.config.onHoverExit?.call();
      }
    }
  }

  void _onHorizontalDragStart(DragStartDetails _) {
    if (widget.direction == Axis.horizontal) {
      setState(() => isDragging = true);
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.direction == Axis.horizontal) {
      widget.onResizeUpdate(details.delta.dx);
    }
  }

  void _onHorizontalDragEnd(DragEndDetails _) {
    if (widget.direction == Axis.horizontal) {
      setState(() => isDragging = false);

      if (!isHovered) {
        widget.config.onHoverExit?.call();
      }
    }
  }
}

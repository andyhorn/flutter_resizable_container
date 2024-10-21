import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/divider_painter.dart';
import 'package:flutter_resizable_container/src/resizable_divider.dart';
import 'package:flutter_resizable_container/src/resizable_size.dart';

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
    return LayoutBuilder(builder: (context, constraints) {
      final width = _getWidth(constraints.maxWidth);
      final height = _getHeight(constraints.maxHeight);

      return Align(
        alignment: switch (widget.config.crossAxisAlignment) {
          CrossAxisAlignment.start => switch (widget.direction) {
              Axis.horizontal => Alignment.topCenter,
              Axis.vertical => Alignment.centerLeft,
            },
          CrossAxisAlignment.end => switch (widget.direction) {
              Axis.horizontal => Alignment.bottomCenter,
              Axis.vertical => Alignment.bottomRight,
            },
          _ => Alignment.center,
        },
        child: MouseRegion(
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
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            child: CustomPaint(
              size: Size(width, height),
              painter: DividerPainter(
                direction: widget.direction,
                color: widget.config.color ?? Theme.of(context).dividerColor,
                thickness: widget.config.thickness,
                crossAxisAlignment: widget.config.crossAxisAlignment,
                length: widget.config.length,
                mainAxisAlignment: widget.config.mainAxisAlignment,
                padding: widget.config.padding,
              ),
            ),
          ),
        ),
      );
    });
  }

  MouseCursor _getCursor() {
    return switch (widget.direction) {
      Axis.horizontal => SystemMouseCursors.resizeLeftRight,
      Axis.vertical => SystemMouseCursors.resizeUpDown,
    };
  }

  double _getHeight(double maxHeight) {
    return switch (widget.direction) {
      Axis.horizontal => switch (widget.config.length.type) {
          SizeType.pixels => min(widget.config.length.value, maxHeight),
          SizeType.expand => maxHeight,
          SizeType.ratio => maxHeight * widget.config.length.value,
          SizeType.shrink => 0.0,
        },
      Axis.vertical => widget.config.thickness + widget.config.padding,
    };
  }

  double _getWidth(double maxWidth) {
    return switch (widget.direction) {
      Axis.horizontal => widget.config.thickness + widget.config.padding,
      Axis.vertical => switch (widget.config.length.type) {
          SizeType.pixels => min(widget.config.length.value, maxWidth),
          SizeType.expand => maxWidth,
          SizeType.ratio => maxWidth * widget.config.length.value,
          SizeType.shrink => 0.0,
        },
    };
  }

  void _onEnter(PointerEnterEvent _) {
    setState(() => isHovered = true);
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

  void _onTapDown(TapDownDetails _) {
    widget.config.onTapDown?.call();
  }

  void _onTapUp(TapUpDetails _) {
    widget.config.onTapUp?.call();
  }
}

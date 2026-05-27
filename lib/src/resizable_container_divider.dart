import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/divider_painter.dart';
import 'package:flutter_resizable_container/src/resizable_size.dart';

class ResizableContainerDivider extends StatefulWidget {
  const ResizableContainerDivider({
    super.key,
    required this.direction,
    required this.config,
    required this.crossAxisSize,
    required void Function(double) this.onResizeUpdate,
  });

  const ResizableContainerDivider.placeholder({
    super.key,
    required this.config,
    required this.direction,
    required this.crossAxisSize,
  }) : onResizeUpdate = null;

  final Axis direction;
  final void Function(double)? onResizeUpdate;
  final ResizableDivider config;

  /// The resolved cross-axis paint dimension for the divider, computed
  /// upstream by applying [ResizableDivider.length] against the parent's
  /// cross-axis max.
  final double crossAxisSize;

  @override
  State<ResizableContainerDivider> createState() =>
      _ResizableContainerDividerState();
}

class _ResizableContainerDividerState extends State<ResizableContainerDivider> {
  bool isDragging = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final mainAxisSize = widget.config.thickness + widget.config.padding;
    final size = switch (widget.direction) {
      Axis.horizontal => Size(mainAxisSize, widget.crossAxisSize),
      Axis.vertical => Size(widget.crossAxisSize, mainAxisSize),
    };

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
          onHorizontalDragUpdate: _getOnHorizontalDragUpdate(
            Directionality.of(context),
          ),
          onHorizontalDragEnd: _onHorizontalDragEnd,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          child: CustomPaint(
            size: size,
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
  }

  MouseCursor _getCursor() {
    return switch (widget.direction) {
      Axis.horizontal =>
        widget.config.cursor ?? SystemMouseCursors.resizeLeftRight,
      Axis.vertical => widget.config.cursor ?? SystemMouseCursors.resizeUpDown,
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
      widget.config.onDragStart?.call();
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (widget.direction == Axis.vertical) {
      widget.onResizeUpdate?.call(details.delta.dy);
    }
  }

  void _onVerticalDragEnd(DragEndDetails _) {
    if (widget.direction == Axis.vertical) {
      setState(() => isDragging = false);
      widget.config.onDragEnd?.call();

      if (!isHovered) {
        widget.config.onHoverExit?.call();
      }
    }
  }

  void _onHorizontalDragStart(DragStartDetails _) {
    if (widget.direction == Axis.horizontal) {
      setState(() => isDragging = true);
      widget.config.onDragStart?.call();
    }
  }

  void Function(DragUpdateDetails) _getOnHorizontalDragUpdate(
    TextDirection textDirection,
  ) {
    return (details) {
      if (widget.direction == Axis.horizontal) {
        final delta = details.delta.dx;

        widget.onResizeUpdate?.call(switch (textDirection) {
          TextDirection.ltr => delta,
          TextDirection.rtl => -delta,
        });
      }
    };
  }

  void _onHorizontalDragEnd(DragEndDetails _) {
    if (widget.direction == Axis.horizontal) {
      setState(() => isDragging = false);
      widget.config.onDragEnd?.call();

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

/// Resolves [length] against the available cross-axis [max].
///
/// Mirrors the per-arm semantics that previously lived inside the divider's
/// `LayoutBuilder`-driven `_getWidth` / `_getHeight` helpers.
double resolveDividerCrossAxisSize(ResizableSize length, double max) {
  return switch (length) {
    ResizableSizePixels(:final pixels) => min(pixels, max),
    ResizableSizeExpand() => max,
    ResizableSizeRatio(:final ratio) => max * ratio,
    ResizableSizeShrink() => 0.0,
  };
}

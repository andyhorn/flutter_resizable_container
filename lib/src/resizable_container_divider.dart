import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/divider_painter.dart';

class ResizableContainerDivider extends StatefulWidget {
  const ResizableContainerDivider({
    super.key,
    required this.direction,
    required this.config,
    required this.onResizeUpdate,
    this.enabled = true,
  });

  final Axis direction;
  final void Function(double) onResizeUpdate;
  final ResizableDivider config;

  /// Whether this divider responds to drag, tap, and hover input. When
  /// `false`, gesture handlers and the resize cursor are suppressed; the
  /// divider remains visible.
  final bool enabled;

  @override
  State<ResizableContainerDivider> createState() =>
      _ResizableContainerDividerState();
}

class _ResizableContainerDividerState extends State<ResizableContainerDivider> {
  bool isDragging = false;
  bool isHovered = false;

  @override
  void didUpdateWidget(covariant ResizableContainerDivider oldWidget) {
    super.didUpdateWidget(oldWidget);

    final becameDisabled = oldWidget.enabled && !widget.enabled;
    if (!becameDisabled) return;

    final wasDragging = isDragging;
    final wasHovered = isHovered;
    if (!wasDragging && !wasHovered) return;

    isDragging = false;
    isHovered = false;

    // Deferred because this runs during layout, and consumers commonly call
    // `setState` from these callbacks.
    final config = oldWidget.config;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (wasDragging) config.onDragEnd?.call();
      config.onHoverExit?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = _getWidth(constraints.maxWidth);
      final height = _getHeight(constraints.maxHeight);
      final canResize = widget.enabled;
      final isHorizontal = widget.direction == Axis.horizontal;
      final onDragStart = canResize ? _onDragStart : null;
      final onDragUpdate =
          canResize ? _getOnDragUpdate(Directionality.of(context)) : null;
      final onDragEnd = canResize ? _onDragEnd : null;

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
            onVerticalDragStart: isHorizontal ? null : onDragStart,
            onVerticalDragUpdate: isHorizontal ? null : onDragUpdate,
            onVerticalDragEnd: isHorizontal ? null : onDragEnd,
            onHorizontalDragStart: isHorizontal ? onDragStart : null,
            onHorizontalDragUpdate: isHorizontal ? onDragUpdate : null,
            onHorizontalDragEnd: isHorizontal ? onDragEnd : null,
            onTapDown: widget.enabled ? _onTapDown : null,
            onTapUp: widget.enabled ? _onTapUp : null,
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
    if (!widget.enabled) {
      return widget.config.cursor ?? MouseCursor.defer;
    }
    return switch (widget.direction) {
      Axis.horizontal =>
        widget.config.cursor ?? SystemMouseCursors.resizeLeftRight,
      Axis.vertical => widget.config.cursor ?? SystemMouseCursors.resizeUpDown,
    };
  }

  double _getHeight(double maxHeight) {
    return switch (widget.direction) {
      Axis.horizontal => switch (widget.config.length) {
          ResizableSizePixels(:final pixels) => min(pixels, maxHeight),
          ResizableSizeExpand() => maxHeight,
          ResizableSizeRatio(:final ratio) => maxHeight * ratio,
          ResizableSizeShrink() => 0.0,
        },
      Axis.vertical => widget.config.thickness + widget.config.padding,
    };
  }

  double _getWidth(double maxWidth) {
    return switch (widget.direction) {
      Axis.horizontal => widget.config.thickness + widget.config.padding,
      Axis.vertical => switch (widget.config.length) {
          ResizableSizePixels(:final pixels) => min(pixels, maxWidth),
          ResizableSizeExpand() => maxWidth,
          ResizableSizeRatio(:final ratio) => maxWidth * ratio,
          ResizableSizeShrink() => 0.0,
        },
    };
  }

  void _onEnter(PointerEnterEvent _) {
    if (!widget.enabled) return;
    setState(() => isHovered = true);
    widget.config.onHoverEnter?.call();
  }

  void _onExit(PointerExitEvent _) {
    if (!widget.enabled) return;
    setState(() => isHovered = false);

    if (!isDragging) {
      widget.config.onHoverExit?.call();
    }
  }

  void _onDragStart(DragStartDetails _) {
    setState(() => isDragging = true);
    widget.config.onDragStart?.call();
  }

  void Function(DragUpdateDetails) _getOnDragUpdate(
    TextDirection textDirection,
  ) {
    return (details) {
      final delta = switch (widget.direction) {
        Axis.horizontal => details.delta.dx,
        Axis.vertical => details.delta.dy,
      };
      final isFlipped = widget.direction == Axis.horizontal &&
          textDirection == TextDirection.rtl;

      widget.onResizeUpdate(isFlipped ? -delta : delta);
    };
  }

  void _onDragEnd(DragEndDetails _) {
    setState(() => isDragging = false);
    widget.config.onDragEnd?.call();

    if (!isHovered) {
      widget.config.onHoverExit?.call();
    }
  }

  void _onTapDown(TapDownDetails _) {
    widget.config.onTapDown?.call();
  }

  void _onTapUp(TapUpDetails _) {
    widget.config.onTapUp?.call();
  }
}

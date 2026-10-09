import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/extensions/divider_layout_ext.dart';

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
      final canResize = widget.enabled;
      final isHorizontal = widget.direction == Axis.horizontal;
      final onDragStart = canResize ? _onDragStart : null;
      final onDragUpdate =
          canResize ? _getOnDragUpdate(Directionality.of(context)) : null;
      final onDragEnd = canResize ? _onDragEnd : null;

      return Align(
        alignment: widget.config.alignmentFor(widget.direction),
        child: MouseRegion(
          cursor: _getCursor(),
          opaque: false,
          onEnter: _onEnter,
          onExit: _onExit,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragStart: isHorizontal ? null : onDragStart,
            onVerticalDragUpdate: isHorizontal ? null : onDragUpdate,
            onVerticalDragEnd: isHorizontal ? null : onDragEnd,
            onHorizontalDragStart: isHorizontal ? onDragStart : null,
            onHorizontalDragUpdate: isHorizontal ? onDragUpdate : null,
            onHorizontalDragEnd: isHorizontal ? onDragEnd : null,
            onTapDown: widget.enabled ? _onTapDown : null,
            onTapUp: widget.enabled ? _onTapUp : null,
            child: SizedBox.fromSize(
              size: widget.config.sizeFor(widget.direction, constraints),
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

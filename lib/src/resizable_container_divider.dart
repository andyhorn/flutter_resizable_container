import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/divider_painter.dart';
import 'package:flutter_resizable_container/src/extensions/divider_layout_ext.dart';

class ResizableContainerDivider extends StatefulWidget {
  const ResizableContainerDivider({
    super.key,
    required this.direction,
    required this.config,
    required this.onResizeUpdate,
    required this.positionAfter,
    this.enabled = true,
  });

  final Axis direction;
  final void Function(double) onResizeUpdate;

  /// The fraction of the total child size before this divider once `delta` is
  /// applied with all size constraints; a `delta` of 0 gives the current
  /// position.
  final double Function(double delta) positionAfter;
  final ResizableDivider config;

  /// Whether this divider responds to drag, tap, hover, keyboard, and
  /// semantic input. When `false`, gesture handlers and the resize cursor are
  /// suppressed and the divider cannot be focused; the divider remains
  /// visible and is exposed as a disabled slider.
  final bool enabled;

  @override
  State<ResizableContainerDivider> createState() =>
      _ResizableContainerDividerState();
}

class _ResizableContainerDividerState extends State<ResizableContainerDivider> {
  static const _shiftMultiplier = 5;

  final _focusNode = FocusNode(debugLabel: 'ResizableContainerDivider');

  bool isDragging = false;
  bool isHovered = false;
  bool _showFocusHighlight = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final canResize = widget.enabled;
        final isHorizontal = widget.direction == Axis.horizontal;
        final textDirection = Directionality.of(context);
        final onDragStart = canResize ? _onDragStart : null;
        final onDragUpdate = canResize ? _getOnDragUpdate(textDirection) : null;
        final onDragEnd = canResize ? _onDragEnd : null;
        final size = widget.config.sizeFor(widget.direction, constraints);
        final hitArea = widget.config.hitAreaFor(widget.direction, constraints);

        return Align(
          alignment: widget.config.alignmentFor(widget.direction),
          child: MouseRegion(
            cursor: _getCursor(),
            opaque: false,
            onEnter: _onEnter,
            onExit: _onExit,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              excludeFromSemantics: true,
              onVerticalDragStart: isHorizontal ? null : onDragStart,
              onVerticalDragUpdate: isHorizontal ? null : onDragUpdate,
              onVerticalDragEnd: isHorizontal ? null : onDragEnd,
              onHorizontalDragStart: isHorizontal ? onDragStart : null,
              onHorizontalDragUpdate: isHorizontal ? onDragUpdate : null,
              onHorizontalDragEnd: isHorizontal ? onDragEnd : null,
              onTapDown: widget.enabled ? _onTapDown : null,
              onTapUp: widget.enabled ? _onTapUp : null,
              child: _DividerSemantics(
                label: widget.config.semanticLabel,
                enabled: widget.enabled,
                value: _percent(widget.positionAfter(0)),
                increasedValue: _percent(
                  widget.positionAfter(widget.config.keyboardStep),
                ),
                decreasedValue: _percent(
                  widget.positionAfter(-widget.config.keyboardStep),
                ),
                onIncrease: () =>
                    widget.onResizeUpdate(widget.config.keyboardStep),
                onDecrease: () =>
                    widget.onResizeUpdate(-widget.config.keyboardStep),
                child: FocusableActionDetector(
                  enabled: widget.enabled,
                  focusNode: _focusNode,
                  shortcuts: _shortcuts(),
                  actions: {
                    _ResizeDividerIntent: CallbackAction<_ResizeDividerIntent>(
                      onInvoke: (intent) {
                        widget.onResizeUpdate(
                          _toLogicalDelta(intent.delta, textDirection),
                        );
                        return null;
                      },
                    ),
                  },
                  onShowFocusHighlight: _onShowFocusHighlight,
                  child: SizedBox.fromSize(
                    size: hitArea,
                    child: _showFocusHighlight
                        ? Center(
                            child: SizedBox.fromSize(
                              size: size,
                              child: _FocusIndicator(
                                config: widget.config,
                                direction: widget.direction,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _percent(double fraction) => '${(fraction * 100).round()}%';

  Map<ShortcutActivator, Intent> _shortcuts() {
    final (backward, forward) = switch (widget.direction) {
      Axis.horizontal => (
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowRight,
        ),
      Axis.vertical => (
          LogicalKeyboardKey.arrowUp,
          LogicalKeyboardKey.arrowDown,
        ),
    };
    final step = widget.config.keyboardStep;
    final shiftStep = step * _shiftMultiplier;

    return {
      SingleActivator(backward): _ResizeDividerIntent(-step),
      SingleActivator(forward): _ResizeDividerIntent(step),
      SingleActivator(backward, shift: true): _ResizeDividerIntent(-shiftStep),
      SingleActivator(forward, shift: true): _ResizeDividerIntent(shiftStep),
    };
  }

  void _onShowFocusHighlight(bool show) {
    setState(() => _showFocusHighlight = show);
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
    _focusNode.requestFocus();
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

      widget.onResizeUpdate(_toLogicalDelta(delta, textDirection));
    };
  }

  /// Converts a delta along the screen axis into one measured from the leading
  /// child, which is mirrored for horizontal containers in RTL.
  double _toLogicalDelta(double delta, TextDirection textDirection) {
    final isFlipped = widget.direction == Axis.horizontal &&
        textDirection == TextDirection.rtl;

    return isFlipped ? -delta : delta;
  }

  void _onDragEnd(DragEndDetails _) {
    setState(() => isDragging = false);
    widget.config.onDragEnd?.call();

    if (!isHovered) {
      widget.config.onHoverExit?.call();
    }
  }

  void _onTapDown(TapDownDetails _) {
    _focusNode.requestFocus();
    widget.config.onTapDown?.call();
  }

  void _onTapUp(TapUpDetails _) {
    widget.config.onTapUp?.call();
  }
}

const _focusIndicatorExtraThickness = 2.0;

class _ResizeDividerIntent extends Intent {
  const _ResizeDividerIntent(this.delta);

  final double delta;
}

class _DividerSemantics extends StatelessWidget {
  const _DividerSemantics({
    required this.label,
    required this.enabled,
    required this.value,
    required this.increasedValue,
    required this.decreasedValue,
    required this.onIncrease,
    required this.onDecrease,
    required this.child,
  });

  final String? label;
  final bool enabled;
  final String value;
  final String increasedValue;
  final String decreasedValue;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      slider: true,
      enabled: enabled,
      label: label,
      value: value,
      increasedValue: enabled ? increasedValue : null,
      decreasedValue: enabled ? decreasedValue : null,
      onIncrease: enabled ? onIncrease : null,
      onDecrease: enabled ? onDecrease : null,
      child: child,
    );
  }
}

/// A thicker, primary-colored line painted over the divider's own line while
/// it has keyboard focus.
class _FocusIndicator extends StatelessWidget {
  const _FocusIndicator({required this.config, required this.direction});

  final ResizableDivider config;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: DividerPainter(
          direction: direction,
          color: Theme.of(context).colorScheme.primary,
          thickness: config.thickness + _focusIndicatorExtraThickness,
          crossAxisAlignment: config.crossAxisAlignment,
          length: config.length,
          mainAxisAlignment: config.mainAxisAlignment,
          padding: config.padding,
        ),
      ),
    );
  }
}

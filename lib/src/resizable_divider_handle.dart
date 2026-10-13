import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/divider_painter.dart';
import 'package:flutter_resizable_container/src/extensions/divider_layout_ext.dart';

/// The interactive, focusable part of a divider.
///
/// Handles drag, tap, hover, keyboard, and semantic input, translating them
/// into resize deltas passed to [onResizeUpdate]. The visible line is drawn
/// separately by the container.
class ResizableDividerHandle extends StatefulWidget {
  /// Creates the interactive part of a divider.
  const ResizableDividerHandle({
    super.key,
    required this.direction,
    required this.config,
    required this.onResizeUpdate,
    required this.positionAfter,
    this.enabled = true,
  });

  /// The axis along which the container's children are laid out.
  final Axis direction;

  /// Called with a resize delta, in logical pixels measured from the leading
  /// child, when the user drags, presses an arrow key, or increases or
  /// decreases the divider through semantics.
  final void Function(double) onResizeUpdate;

  /// The fraction of the total child size before this divider once `delta` is
  /// applied with all size constraints; a `delta` of 0 gives the current
  /// position.
  final double Function(double delta) positionAfter;

  /// The appearance, callbacks, and input configuration of this divider.
  final ResizableDivider config;

  /// Whether this divider responds to drag, tap, hover, keyboard, and
  /// semantic input. When `false`, gesture handlers and the resize cursor are
  /// suppressed and the divider cannot be focused; the divider remains
  /// visible but is excluded from semantics.
  final bool enabled;

  @override
  State<ResizableDividerHandle> createState() => _ResizableDividerHandleState();
}

class _ResizableDividerHandleState extends State<ResizableDividerHandle> {
  static const _shiftMultiplier = 5;

  final _focusNode = FocusNode(debugLabel: 'ResizableDividerHandle');

  late final Map<Type, Action<Intent>> _actions = {
    _ResizeDividerIntent: CallbackAction<_ResizeDividerIntent>(
      onInvoke: _onResizeIntent,
    ),
  };
  late Map<ShortcutActivator, Intent> _shortcuts;
  late TextDirection _textDirection;

  bool _isDragging = false;
  bool _isHovered = false;
  bool _showFocusHighlight = false;

  @override
  void initState() {
    super.initState();
    _shortcuts = _buildShortcuts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _textDirection = Directionality.of(context);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ResizableDividerHandle oldWidget) {
    super.didUpdateWidget(oldWidget);

    final shortcutsChanged = oldWidget.direction != widget.direction ||
        oldWidget.config.keyboardStep != widget.config.keyboardStep;
    if (shortcutsChanged) {
      _shortcuts = _buildShortcuts();
    }

    final becameDisabled = oldWidget.enabled && !widget.enabled;
    if (!becameDisabled) return;

    final wasDragging = _isDragging;
    final wasHovered = _isHovered;
    if (!wasDragging && !wasHovered) return;

    _isDragging = false;
    _isHovered = false;

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
        final config = widget.config;
        final enabled = widget.enabled;
        final step = config.keyboardStep;
        final isHorizontal = widget.direction == Axis.horizontal;
        final onDragStart = enabled ? _onDragStart : null;
        final onDragUpdate = enabled ? _onDragUpdate : null;
        final onDragEnd = enabled ? _onDragEnd : null;
        final size = config.sizeFor(widget.direction, constraints);
        final hitArea = config.hitAreaFor(widget.direction, constraints);
        final value = enabled ? _percent(widget.positionAfter(0)) : null;
        final increasedValue =
            enabled ? _percent(widget.positionAfter(step)) : null;
        final decreasedValue =
            enabled ? _percent(widget.positionAfter(-step)) : null;

        return Align(
          alignment: config.alignmentFor(widget.direction),
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
              onTapDown: enabled ? _onTapDown : null,
              onTapUp: enabled ? _onTapUp : null,
              child: _DividerSemantics(
                label: config.semanticLabel,
                excluded: !enabled,
                value: value,
                increasedValue: increasedValue,
                decreasedValue: decreasedValue,
                onIncrease: enabled ? _onIncrease : null,
                onDecrease: enabled ? _onDecrease : null,
                child: _FocusableDividerArea(
                  enabled: enabled,
                  focusNode: _focusNode,
                  shortcuts: _shortcuts,
                  actions: _actions,
                  onShowFocusHighlight: _onShowFocusHighlight,
                  showFocusHighlight: _showFocusHighlight,
                  hitArea: hitArea,
                  size: size,
                  config: config,
                  direction: widget.direction,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _percent(double fraction) => '${(fraction * 100).round()}%';

  Map<ShortcutActivator, Intent> _buildShortcuts() {
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

  Object? _onResizeIntent(_ResizeDividerIntent intent) {
    widget.onResizeUpdate(_toLogicalDelta(intent.delta));
    return null;
  }

  void _onIncrease() => widget.onResizeUpdate(widget.config.keyboardStep);

  void _onDecrease() => widget.onResizeUpdate(-widget.config.keyboardStep);

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
    setState(() => _isHovered = true);
    widget.config.onHoverEnter?.call();
  }

  void _onExit(PointerExitEvent _) {
    if (!widget.enabled) return;
    setState(() => _isHovered = false);

    if (!_isDragging) {
      widget.config.onHoverExit?.call();
    }
  }

  // Touch input must not take focus from pane content such as a text field,
  // which would dismiss its soft keyboard.
  void _requestFocusUnlessTouch(PointerDeviceKind? kind) {
    final isTouchOrUnknown = kind == null || kind == PointerDeviceKind.touch;
    if (isTouchOrUnknown) return;

    _focusNode.requestFocus();
  }

  void _onDragStart(DragStartDetails details) {
    _requestFocusUnlessTouch(details.kind);
    setState(() => _isDragging = true);
    widget.config.onDragStart?.call();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final delta = switch (widget.direction) {
      Axis.horizontal => details.delta.dx,
      Axis.vertical => details.delta.dy,
    };

    widget.onResizeUpdate(_toLogicalDelta(delta));
  }

  /// Converts a delta along the screen axis into one measured from the leading
  /// child, which is mirrored for horizontal containers in RTL.
  double _toLogicalDelta(double delta) {
    final isFlipped = widget.direction == Axis.horizontal &&
        _textDirection == TextDirection.rtl;

    return isFlipped ? -delta : delta;
  }

  void _onDragEnd(DragEndDetails _) {
    setState(() => _isDragging = false);
    widget.config.onDragEnd?.call();

    if (!_isHovered) {
      widget.config.onHoverExit?.call();
    }
  }

  void _onTapDown(TapDownDetails details) {
    _requestFocusUnlessTouch(details.kind);
    widget.config.onTapDown?.call();
  }

  void _onTapUp(TapUpDetails _) {
    widget.config.onTapUp?.call();
  }
}

const _focusRingOverhang = 1.0;

class _ResizeDividerIntent extends Intent {
  const _ResizeDividerIntent(this.delta);

  final double delta;

  @override
  bool operator ==(Object other) {
    return other is _ResizeDividerIntent && other.delta == delta;
  }

  @override
  int get hashCode => delta.hashCode;
}

class _FocusableDividerArea extends StatelessWidget {
  const _FocusableDividerArea({
    required this.enabled,
    required this.focusNode,
    required this.shortcuts,
    required this.actions,
    required this.onShowFocusHighlight,
    required this.showFocusHighlight,
    required this.hitArea,
    required this.size,
    required this.config,
    required this.direction,
  });

  final bool enabled;
  final FocusNode focusNode;
  final Map<ShortcutActivator, Intent> shortcuts;
  final Map<Type, Action<Intent>> actions;
  final ValueChanged<bool> onShowFocusHighlight;
  final bool showFocusHighlight;
  final Size hitArea;
  final Size size;
  final ResizableDivider config;
  final Axis direction;

  Rect _lineRect() {
    final thickness = config.thickness;
    final isHorizontal = direction == Axis.horizontal;
    final extent = isHorizontal ? size.width : size.height;
    final start = switch (config.mainAxisAlignment) {
      MainAxisAlignment.start => 0.0,
      MainAxisAlignment.end => extent - thickness,
      _ => (extent - thickness) / 2,
    };

    return isHorizontal
        ? Rect.fromLTWH(start, 0, thickness, size.height)
        : Rect.fromLTWH(0, start, size.width, thickness);
  }

  @override
  Widget build(BuildContext context) {
    final indicator = showFocusHighlight
        ? Center(
            child: SizedBox.fromSize(
              size: size,
              child: _FocusIndicator(
                config: config,
                direction: direction,
                lineRect: _lineRect(),
              ),
            ),
          )
        : null;

    return FocusableActionDetector(
      enabled: enabled,
      focusNode: focusNode,
      shortcuts: shortcuts,
      actions: actions,
      onShowFocusHighlight: onShowFocusHighlight,
      child: SizedBox.fromSize(size: hitArea, child: indicator),
    );
  }
}

class _DividerSemantics extends StatelessWidget {
  const _DividerSemantics({
    required this.label,
    required this.excluded,
    required this.value,
    required this.increasedValue,
    required this.decreasedValue,
    required this.onIncrease,
    required this.onDecrease,
    required this.child,
  });

  final String? label;
  final bool excluded;
  final String? value;
  final String? increasedValue;
  final String? decreasedValue;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      excluding: excluded,
      child: Semantics(
        container: true,
        slider: true,
        enabled: true,
        label: label,
        value: value,
        increasedValue: increasedValue,
        decreasedValue: decreasedValue,
        onIncrease: onIncrease,
        onDecrease: onDecrease,
        child: child,
      ),
    );
  }
}

/// A thicker line in the focus color painted around the divider's own line
/// while it has keyboard focus.
class _FocusIndicator extends StatelessWidget {
  const _FocusIndicator({
    required this.config,
    required this.direction,
    required this.lineRect,
  });

  final ResizableDivider config;
  final Axis direction;
  final Rect lineRect;

  @override
  Widget build(BuildContext context) {
    final ringRect = switch (direction) {
      Axis.horizontal => Rect.fromLTRB(
          lineRect.left - _focusRingOverhang,
          lineRect.top,
          lineRect.right + _focusRingOverhang,
          lineRect.bottom,
        ),
      Axis.vertical => Rect.fromLTRB(
          lineRect.left,
          lineRect.top - _focusRingOverhang,
          lineRect.right,
          lineRect.bottom + _focusRingOverhang,
        ),
    };

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fromRect(
          rect: ringRect,
          child: IgnorePointer(
            child: CustomPaint(
              painter: DividerPainter(
                direction: direction,
                color:
                    config.focusColor ?? Theme.of(context).colorScheme.primary,
                thickness: config.thickness + 2 * _focusRingOverhang,
                crossAxisAlignment: config.crossAxisAlignment,
                length: config.length,
                mainAxisAlignment: MainAxisAlignment.center,
                padding: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

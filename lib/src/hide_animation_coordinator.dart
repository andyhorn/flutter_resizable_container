import 'package:flutter/widgets.dart';
import 'package:flutter_resizable_container/src/resizable_hide_animation.dart';

/// Where in the hide/show animation lifecycle the coordinator is.
enum HideAnimationPhase {
  /// No animation in flight. The widget should render from its own source of
  /// truth (the controller's sizes).
  idle,

  /// A transition is starting: the from-snapshot has been captured, but the
  /// target has not yet been measured. The widget should still render the
  /// from-snapshot while a layout pass measures the target offstage.
  capturing,

  /// The animation is running. The widget should render
  /// [HideAnimationCoordinator.currentSizes].
  animating,
}

/// Owns the animation state for `ResizableContainer.hideAnimation`.
///
/// The coordinator tracks the from/to snapshots, drives the
/// [AnimationController], and exposes the interpolated sizes the widget
/// should render. The widget owns the rendering decisions; this class owns
/// the math and lifecycle.
class HideAnimationCoordinator {
  HideAnimationCoordinator({
    required TickerProvider vsync,
    required VoidCallback onChanged,
  })  : _vsync = vsync,
        _onChanged = onChanged;

  final TickerProvider _vsync;
  final VoidCallback _onChanged;

  AnimationController? _controller;
  List<double>? _from;
  List<double>? _to;
  Curve _curve = Curves.linear;

  HideAnimationPhase get phase {
    if (_from == null) return HideAnimationPhase.idle;
    if (_to == null) return HideAnimationPhase.capturing;
    return HideAnimationPhase.animating;
  }

  /// The full alternating list of child + divider pixel sizes the widget
  /// should render right now.
  ///
  /// Returns `null` in [HideAnimationPhase.idle], signaling the caller should
  /// fall back to its own source of truth.
  List<double>? get currentSizes {
    final from = _from;
    if (from == null) return null;

    final to = _to;
    if (to == null) return List.of(from);

    final t = _curve.transform(_controller!.value);
    return [
      for (var i = 0; i < from.length; i++) from[i] + (to[i] - from[i]) * t,
    ];
  }

  /// Capture a new from-snapshot to begin a transition.
  ///
  /// If an animation is already running, the currently interpolated sizes
  /// are kept as the new from-snapshot — preserving visual continuity when
  /// the user reverses direction mid-flight. Otherwise [fallbackFrom] is
  /// used.
  void beginCapture(List<double> fallbackFrom) {
    final newFrom =
        phase == HideAnimationPhase.animating ? currentSizes! : fallbackFrom;
    _controller?.stop();
    _from = newFrom;
    _to = null;
  }

  /// Begin the animation toward [target] using [animation].
  ///
  /// Must be called after [beginCapture]. Lazily constructs the underlying
  /// [AnimationController] on first use.
  void startAnimation({
    required List<double> target,
    required ResizableHideAnimation animation,
  }) {
    if (_from == null) return;

    _to = target;
    _curve = animation.curve;

    final controller = _controller ??= AnimationController(vsync: _vsync)
      ..addListener(_onChanged)
      ..addStatusListener(_handleStatus);

    controller
      ..duration = animation.duration
      ..forward(from: 0.0);
  }

  /// Stop any in-flight animation and return to [HideAnimationPhase.idle].
  void cancel() {
    _controller?.stop();
    _from = null;
    _to = null;
  }

  /// Cancel and dispose the underlying [AnimationController]. The coordinator
  /// remains reusable; the next [startAnimation] will create a new
  /// controller.
  void reset() {
    final c = _controller;
    if (c != null) {
      c
        ..stop()
        ..dispose();
      _controller = null;
    }
    _from = null;
    _to = null;
  }

  void dispose() => reset();

  void _handleStatus(AnimationStatus status) {
    // Only react to natural completion. `forward(from: 0.0)` transiently
    // reports `dismissed` before the new tween starts, and clearing state
    // there would suppress the new animation entirely.
    if (status != AnimationStatus.completed) return;
    _from = null;
    _to = null;
    _onChanged();
  }
}

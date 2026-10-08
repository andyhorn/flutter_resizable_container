import 'package:flutter/widgets.dart';
import 'package:flutter_resizable_container/src/resizable_hide_animation.dart';

/// Where in the hide/show animation lifecycle the coordinator is.
enum HideAnimationPhase {
  /// No animation in flight. The widget should render from its own source of
  /// truth (the controller's sizes).
  idle,

  /// A transition is starting: the from-snapshot has been captured, but the
  /// animation has not started. The widget should still render the
  /// from-snapshot for one frame, after which the target is computed and the
  /// animation begins.
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
  bool _targetScheduled = false;

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
  /// the user reverses direction mid-flight. If a capture is already pending
  /// its from-snapshot is kept, since it is the last thing actually rendered.
  /// Otherwise [fallbackFrom] is used.
  void beginCapture(List<double> fallbackFrom) {
    if (phase == HideAnimationPhase.capturing) return;

    final newFrom =
        phase == HideAnimationPhase.animating ? currentSizes! : fallbackFrom;
    _controller?.stop();
    _from = newFrom;
    _to = null;
  }

  /// Whether the caller should schedule the work that ends the current
  /// [HideAnimationPhase.capturing] phase.
  ///
  /// Returns `true` at most once per capture, so repeated builds within the
  /// capture frame schedule a single callback.
  bool claimTargetSlot() {
    if (phase != HideAnimationPhase.capturing || _targetScheduled) {
      return false;
    }
    _targetScheduled = true;
    return true;
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
    _targetScheduled = false;
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
    _targetScheduled = false;
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
    _targetScheduled = false;
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

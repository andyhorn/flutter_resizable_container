import 'package:flutter/widgets.dart';

/// Configuration for the implicit animation that runs when a child of a
/// [ResizableContainer] is hidden or shown via [ResizableController.hide] or
/// [ResizableController.show].
///
/// Pass an instance to [ResizableContainer.hideAnimation] to opt in. When
/// `null` (the default), hide/show transitions snap to their target in a
/// single frame.
class ResizableHideAnimation {
  /// Creates a [ResizableHideAnimation] with the given [duration] and [curve].
  const ResizableHideAnimation({
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
  });

  /// The total length of the hide or show transition.
  ///
  /// Defaults to 200 milliseconds.
  final Duration duration;

  /// The curve applied to the animation's progress.
  ///
  /// Defaults to [Curves.easeInOut].
  final Curve curve;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResizableHideAnimation &&
          other.duration == duration &&
          other.curve == curve;

  @override
  int get hashCode => Object.hash(duration, curve);
}

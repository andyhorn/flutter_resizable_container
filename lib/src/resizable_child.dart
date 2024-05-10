import 'package:flutter/material.dart';

/// Controls the sizing parameters for the [child] Widget.
class ResizableChild {
  /// Create a new instance of the [ResizableChild] class.
  const ResizableChild({
    required this.child,
    this.expand = false,
    this.maxSize,
    this.minSize,
    this.startingRatio,
  }) : assert(
          startingRatio == null || (startingRatio >= 0 && startingRatio <= 1),
          'The starting ratio must be null or between 0 and 1, inclusive',
        );

  /// Whether this child should expand to fill empty space, even if it extends
  /// beyond its [startingRatio].
  final bool expand;

  /// The (optional) maximum size (in px) of this child Widget.
  final double? maxSize;

  /// The (optional) minimum size (in px) of this child Widget.
  final double? minSize;

  /// The starting size (as a ratio of available space) of the
  /// corresponding widget.
  final double? startingRatio;

  /// The child [Widget]
  final Widget child;

  @override
  String toString() => 'ResizableChildData('
      'startingRatio: $startingRatio, '
      'maxSize: $maxSize, '
      'minSize: $minSize, '
      'child: $child)';

  @override
  operator ==(Object other) =>
      other is ResizableChild &&
      other.startingRatio == startingRatio &&
      other.maxSize == maxSize &&
      other.minSize == minSize &&
      other.child.runtimeType == child.runtimeType;

  @override
  int get hashCode => Object.hash(startingRatio, maxSize, minSize, child);
}

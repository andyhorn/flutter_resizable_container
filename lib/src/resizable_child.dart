import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/src/resizable_size.dart';

/// Controls the sizing parameters for the [child] Widget.
class ResizableChild {
  /// Create a new instance of the [ResizableChild] class.
  const ResizableChild({
    required this.child,
    this.expand = false,
    this.maxSize,
    this.minSize,
    this.startingSize,
  });

  /// Whether this child should expand to fill empty space, even if it extends
  /// beyond its [startingRatio].
  final bool expand;

  /// The (optional) maximum size (in px) of this child Widget.
  final double? maxSize;

  /// The (optional) minimum size (in px) of this child Widget.
  final double? minSize;

  /// The starting size of the corresponding widget. May use a ratio of the
  /// available space or an absolute size in logical pixels.
  ///
  /// ```dart
  /// // Ratio of available space
  /// startingSize: const ResizableStartingSize.ratio(0.25);
  ///
  /// // Absolute size in logical pixels
  /// startingSize: const ResizableStartingSize.pixels(300);
  /// ```
  final ResizableSize? startingSize;

  /// The child [Widget]
  final Widget child;

  @override
  String toString() => 'ResizableChildData('
      'startingSize: $startingSize, '
      'maxSize: $maxSize, '
      'minSize: $minSize, '
      'child: $child, '
      'expand: $expand)';

  @override
  operator ==(Object other) =>
      other is ResizableChild &&
      other.expand == expand &&
      other.startingSize == startingSize &&
      other.maxSize == maxSize &&
      other.minSize == minSize &&
      other.child.runtimeType == child.runtimeType;

  @override
  int get hashCode => Object.hash(
        expand,
        startingSize,
        maxSize,
        minSize,
        child,
      );
}

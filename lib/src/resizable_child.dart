import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/src/resizable_size.dart';

/// Controls the sizing parameters for the [child] Widget.
class ResizableChild {
  /// Create a new instance of the [ResizableChild] class.
  const ResizableChild({
    required this.child,
    required this.size,
    this.maxSize,
    this.minSize,
  });

  /// The (optional) maximum size (in px) of this child Widget.
  final double? maxSize;

  /// The (optional) minimum size (in px) of this child Widget.
  final double? minSize;

  /// The size of the corresponding widget. May use a ratio of the
  /// available space, an absolute size in logical pixels, or it can
  /// auto-expand to fill available space.
  ///
  /// ```dart
  /// // Ratio of available space
  /// size: const ResizableSize.ratio(0.25);
  ///
  /// // Absolute size in logical pixels
  /// size: const ResizableSize.pixels(300);
  ///
  /// // Auto-fill available space
  /// size: const ResizableSize.expand(),
  /// ```
  final ResizableSize size;

  /// The child [Widget]
  final Widget child;

  @override
  String toString() => 'ResizableChildData('
      'size: $size, '
      'maxSize: $maxSize, '
      'minSize: $minSize, '
      'child: $child)';

  @override
  operator ==(Object other) =>
      other is ResizableChild &&
      other.size == size &&
      other.maxSize == maxSize &&
      other.minSize == minSize &&
      other.child.runtimeType == child.runtimeType;

  @override
  int get hashCode => Object.hash(
        size,
        maxSize,
        minSize,
        child,
      );
}

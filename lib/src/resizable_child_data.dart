import 'package:flutter/material.dart';

/// Controls the sizing parameters for the [child] Widget.
class ResizableChildData {
  /// Create a new instance of the [ResizableChildData] class.
  const ResizableChildData({
    required this.child,
    required this.startingRatio,
    this.maxSize,
    this.minSize,
  });

  /// The Widget to be displayed.
  final Widget child;

  /// The (optional) maximum size (in px) of this child Widget.
  final double? maxSize;

  /// The (optional) minimum size (in px) of this child Widget.
  final double? minSize;

  /// The initial ratio of this child Widget, where 0 <= x <= 1.
  ///
  /// This ratio will be used to determine the child's size (in px)
  /// when the container is first rendered and is based on the total
  /// available space.
  final double startingRatio;
}

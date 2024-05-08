import 'package:flutter/material.dart';

class ResizableDivider {
  const ResizableDivider({
    this.thickness = 1.0,
    this.size = 2.0,
    this.color,
    this.indent,
    this.endIndent,
  })  : assert(size >= thickness, '[size] must be >= [thickness].'),
        assert(thickness > 0, '[thickness] must be > 0.');

  /// The thickness of the line drawn within the divider.
  ///
  /// Defaults to 1.0.
  final double thickness;

  /// The divider's size (height/width) extent.
  /// The divider line will be drawn in the center of this space.
  ///
  /// Defaults to 2.0.
  final double size;

  /// The color of the dividers between children.
  ///
  /// Defaults to [ThemeData.dividerColor].
  final Color? color;

  /// The amount of empty space to the leading edge of the divider.
  ///
  /// For dividers running from top-to-bottom, this adds empty space at the top.
  /// For dividers running from left-to-right, this adds empty space to the left.
  final double? indent;

  /// The amount of empty space to the trailing edge of the divider.
  ///
  /// For dividers running from top-to-bottom, this adds empty space at the bottom.
  /// For dividers running from left-to-right, this adds empty space to the right.
  final double? endIndent;
}

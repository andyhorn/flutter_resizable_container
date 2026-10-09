import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';

extension DividerLayoutExt on ResizableDivider {
  Alignment alignmentFor(Axis direction) {
    return switch (crossAxisAlignment) {
      CrossAxisAlignment.start => switch (direction) {
          Axis.horizontal => Alignment.topCenter,
          Axis.vertical => Alignment.centerLeft,
        },
      CrossAxisAlignment.end => switch (direction) {
          Axis.horizontal => Alignment.bottomCenter,
          Axis.vertical => Alignment.bottomRight,
        },
      _ => Alignment.center,
    };
  }

  Size sizeFor(Axis direction, BoxConstraints constraints) {
    return switch (direction) {
      Axis.horizontal => Size(
          thickness + padding,
          _crossAxisLength(constraints.maxHeight),
        ),
      Axis.vertical => Size(
          _crossAxisLength(constraints.maxWidth),
          thickness + padding,
        ),
    };
  }

  Size hitAreaFor(Axis direction, BoxConstraints constraints) {
    final size = sizeFor(direction, constraints);
    return switch (direction) {
      Axis.horizontal => Size(size.width + 2 * hitSlop, size.height),
      Axis.vertical => Size(size.width, size.height + 2 * hitSlop),
    };
  }

  double _crossAxisLength(double maxExtent) {
    return switch (length) {
      ResizableSizePixels(:final pixels) => min(pixels, maxExtent),
      ResizableSizeExpand() => maxExtent,
      ResizableSizeRatio(:final ratio) => maxExtent * ratio,
      ResizableSizeShrink() => 0.0,
    };
  }
}

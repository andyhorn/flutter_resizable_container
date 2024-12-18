import 'package:flutter/widgets.dart';

sealed class ResizableLayoutDirection {
  const ResizableLayoutDirection._();

  factory ResizableLayoutDirection.forAxis(Axis direction) {
    return switch (direction) {
      Axis.horizontal => _ResizableHorizontalLayoutHelper(),
      Axis.vertical => _ResizableVerticalLayoutHelper(),
    };
  }

  double getMaxConstraintDimension(BoxConstraints constraints);
  double getSizeDimension(Size size);
  Offset getOffset(double currentPosition);
  Size getSize(double value, BoxConstraints constraints);
  double getMinIntrinsicDimension(RenderBox child);
}

class _ResizableHorizontalLayoutHelper extends ResizableLayoutDirection {
  const _ResizableHorizontalLayoutHelper() : super._();

  @override
  double getMaxConstraintDimension(BoxConstraints constraints) {
    return constraints.maxWidth;
  }

  @override
  Offset getOffset(double currentPosition) {
    return Offset(currentPosition, 0.0);
  }

  @override
  double getSizeDimension(Size size) {
    return size.width;
  }

  @override
  Size getSize(double value, BoxConstraints constraints) {
    return Size(value, constraints.maxHeight);
  }

  @override
  double getMinIntrinsicDimension(RenderBox child) {
    return child.getMinIntrinsicWidth(double.infinity);
  }
}

class _ResizableVerticalLayoutHelper extends ResizableLayoutDirection {
  const _ResizableVerticalLayoutHelper() : super._();

  @override
  double getMaxConstraintDimension(BoxConstraints constraints) {
    return constraints.maxHeight;
  }

  @override
  Offset getOffset(double currentPosition) {
    return Offset(0.0, currentPosition);
  }

  @override
  double getSizeDimension(Size size) {
    return size.height;
  }

  @override
  Size getSize(double value, BoxConstraints constraints) {
    return Size(constraints.maxWidth, value);
  }

  @override
  double getMinIntrinsicDimension(RenderBox child) {
    return child.getMinIntrinsicHeight(double.infinity);
  }
}

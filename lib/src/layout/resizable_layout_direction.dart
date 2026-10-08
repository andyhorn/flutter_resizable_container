import 'package:flutter/widgets.dart';

sealed class ResizableLayoutDirection {
  const ResizableLayoutDirection._();

  factory ResizableLayoutDirection.forAxis(Axis direction) {
    return switch (direction) {
      Axis.horizontal => const ResizableHorizontalLayout(),
      Axis.vertical => const ResizableVerticalLayout(),
    };
  }

  double getMaxConstraint(BoxConstraints constraints);
  double getSizeDimension(Size size);
  Offset getOffset(double currentPosition);

  /// Offset of a child spanning [extent] at [position] in a right-to-left
  /// layout of [containerSize].
  Offset getRtlOffset(double position, double extent, Size containerSize);
  Size getSize(double value, BoxConstraints constraints);
  double getMinIntrinsicDimension(RenderBox child);
  BoxConstraints copyConstraintsWith(BoxConstraints constraints, double value);
  BoxConstraints getShrinkMeasureConstraints(
    BoxConstraints constraints,
    double cap,
  );
}

@visibleForTesting
class ResizableHorizontalLayout extends ResizableLayoutDirection {
  const ResizableHorizontalLayout() : super._();

  @override
  double getMaxConstraint(BoxConstraints constraints) {
    return constraints.maxWidth;
  }

  @override
  Offset getOffset(double currentPosition) {
    return Offset(currentPosition, 0.0);
  }

  @override
  Offset getRtlOffset(double position, double extent, Size containerSize) {
    return Offset(containerSize.width - position - extent, 0.0);
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

  @override
  BoxConstraints copyConstraintsWith(BoxConstraints constraints, double value) {
    return constraints.copyWith(minWidth: value, maxWidth: value);
  }

  @override
  BoxConstraints getShrinkMeasureConstraints(
    BoxConstraints constraints,
    double cap,
  ) {
    return BoxConstraints(
      minWidth: 0,
      maxWidth: cap.clamp(0, double.infinity),
      minHeight: constraints.maxHeight,
      maxHeight: constraints.maxHeight,
    );
  }
}

@visibleForTesting
class ResizableVerticalLayout extends ResizableLayoutDirection {
  const ResizableVerticalLayout() : super._();

  @override
  double getMaxConstraint(BoxConstraints constraints) {
    return constraints.maxHeight;
  }

  @override
  Offset getOffset(double currentPosition) {
    return Offset(0.0, currentPosition);
  }

  @override
  Offset getRtlOffset(double position, double extent, Size containerSize) {
    return getOffset(position);
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

  @override
  BoxConstraints copyConstraintsWith(BoxConstraints constraints, double value) {
    return constraints.copyWith(minHeight: value, maxHeight: value);
  }

  @override
  BoxConstraints getShrinkMeasureConstraints(
    BoxConstraints constraints,
    double cap,
  ) {
    return BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      minHeight: 0,
      maxHeight: cap.clamp(0, double.infinity),
    );
  }
}

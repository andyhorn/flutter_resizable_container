import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/extensions/iterable_ext.dart';

typedef OnLayoutCompleteNotifier = void Function(List<double> pixels);

abstract base class ResizableLayoutDelegate extends MultiChildLayoutDelegate {
  ResizableLayoutDelegate._({
    required this.children,
    required this.dividers,
    required this.onLayoutComplete,
  });

  factory ResizableLayoutDelegate.horizontal({
    required List<ResizableChild> children,
    required List<ResizableDivider> dividers,
    required OnLayoutCompleteNotifier onLayoutComplete,
  }) =>
      _HorizontalLayoutDelegate(
        children: children,
        dividers: dividers,
        onLayoutComplete: onLayoutComplete,
      );

  factory ResizableLayoutDelegate.vertical({
    required List<ResizableChild> children,
    required List<ResizableDivider> dividers,
    required OnLayoutCompleteNotifier onLayoutComplete,
  }) =>
      _VerticalLayoutDelegate(
        children: children,
        dividers: dividers,
        onLayoutComplete: onLayoutComplete,
      );

  final List<ResizableChild> children;
  final List<ResizableDivider> dividers;
  final OnLayoutCompleteNotifier onLayoutComplete;

  @override
  void performLayout(Size size) {
    final totalPixels = getLayoutPixels(size);
    final Map<String, double> pixels = {};

    // Lay out dividers.
    var totalDividerPixels = 0.0;
    for (var i = 0; i < dividers.length; i++) {
      final key = 'divider_$i';
      final layout = layoutChild(
        key,
        getDividerConstraints(i, size),
      );
      totalDividerPixels += getLayoutPixels(layout);
      pixels[key] = getLayoutPixels(layout);
    }

    // Lay out shrink children.
    // This is necessary to calculate the total available space for the flex
    // and ratio children.
    var totalShrinkPixels = 0.0;
    for (var i = 0; i < children.length; i++) {
      final child = children[i];

      if (child.size.isShrink) {
        final key = 'child_$i';
        final layout = layoutChild(key, getShrinkConstraints(i, size));
        pixels[key] = getLayoutPixels(layout);
        totalShrinkPixels += pixels[key]!;
      }
    }

    final pixelPixels = _getTotalPixelSpace();
    final flexPixels =
        totalPixels - totalShrinkPixels - totalDividerPixels - pixelPixels;
    final ratioPixels = flexPixels * _getTotalRatio();
    final expandPixels = flexPixels - ratioPixels;
    final pixelsPerFlex = expandPixels / _getTotalFlex();

    for (var i = 0; i < children.length; i++) {
      final child = children[i];

      if (child.size.isShrink) {
        continue;
      }

      final key = 'child_$i';
      final dimension = child.size.isPixels
          ? child.size.value
          : child.size.isRatio
              ? child.size.value * ratioPixels
              : pixelsPerFlex * child.size.value;

      final layout = layoutChild(key, getConstraints(i, size, dimension));
      pixels[key] = getLayoutPixels(layout);
    }

    for (var i = 0; i < children.length; i++) {
      final childKey = 'child_$i';

      positionChild(
        childKey,
        getPosition(i, pixels),
      );
    }

    for (var i = 0; i < dividers.length; i++) {
      final dividerKey = 'divider_$i';

      positionChild(
        dividerKey,
        getDividerPosition(i, pixels),
      );
    }

    final finalSizes = _getFinalSizes(pixels);
    onLayoutComplete(finalSizes);
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) {
    return false;
  }

  double getLayoutPixels(Size size);
  double subtractPixelsFromSize(Size size, double totalPixels);
  BoxConstraints getConstraints(int i, Size size, double dimension);
  BoxConstraints getShrinkConstraints(int i, Size size);
  BoxConstraints getDividerConstraints(int i, Size size);
  Offset getPosition(int i, Map<String, double> pixels);
  Offset getDividerPosition(int i, Map<String, double> pixels);

  double? _getChildMin(int i) =>
      i < children.length - 1 ? children[i].minSize : null;

  double? _getChildMax(int i) =>
      i < children.length - 1 ? children[i].maxSize : null;

  double _getTotalPixelSpace() {
    return children
        .where((child) => child.size.isPixels)
        .sum((child) => child.size.value)
        .toDouble();
  }

  double _getTotalRatio() {
    return children
        .where((child) => child.size.isRatio)
        .sum((child) => child.size.value)
        .toDouble();
  }

  int _getTotalFlex() {
    return children
        .where((child) => child.size.isExpand)
        .sum((child) => child.size.value)
        .toInt();
  }

  List<double> _getFinalSizes(Map<String, double> pixels) {
    final List<double> finalSizes = [];

    for (var i = 0; i < children.length; i++) {
      final childKey = 'child_$i';
      finalSizes.add(pixels[childKey] ?? 0.0);
    }

    return finalSizes;
  }

  double _getSumOfPreviousPixels(Map<String, double> pixels, int i) {
    var sum = 0.0;

    for (var j = 0; j < i; j++) {
      final childKey = 'child_$j';
      final dividerKey = 'divider_$j';

      sum += pixels[childKey] ?? 0.0;
      sum += pixels[dividerKey] ?? 0.0;
    }

    return sum;
  }

  double _getSumOfPreviousPixelsExcludingCurrentDivider(
    Map<String, double> pixels,
    int i,
  ) {
    var sum = 0.0;

    for (var j = 0; j <= i; j++) {
      final childKey = 'child_$j';
      final dividerKey = 'divider_$j';

      sum += pixels[childKey] ?? 0.0;

      if (j == i) {
        break;
      }

      sum += pixels[dividerKey] ?? 0.0;
    }

    return sum;
  }
}

final class _VerticalLayoutDelegate extends ResizableLayoutDelegate {
  _VerticalLayoutDelegate({
    required super.children,
    required super.dividers,
    required super.onLayoutComplete,
  }) : super._();

  @override
  BoxConstraints getConstraints(int i, Size size, double dimension) {
    final min = _getChildMin(i) ?? dimension;
    final max = _getChildMax(i) ?? dimension;

    return BoxConstraints(
      minWidth: size.width,
      maxWidth: size.width,
      minHeight: min,
      maxHeight: max,
    );
  }

  @override
  BoxConstraints getShrinkConstraints(int i, Size size) {
    final min = _getChildMin(i) ?? 0.0;
    final max = _getChildMax(i) ?? double.infinity;

    return BoxConstraints(
      minWidth: size.width,
      maxWidth: size.width,
      minHeight: min,
      maxHeight: max,
    );
  }

  @override
  BoxConstraints getDividerConstraints(int i, Size size) {
    final dividerThickness = dividers[i].thickness + dividers[i].padding;

    return BoxConstraints(
      minWidth: size.width,
      maxWidth: size.width,
      minHeight: dividerThickness,
      maxHeight: dividerThickness,
    );
  }

  @override
  double getLayoutPixels(Size size) {
    return size.height;
  }

  @override
  double subtractPixelsFromSize(Size size, double totalPixels) {
    return size.height - totalPixels;
  }

  @override
  Offset getPosition(int i, Map<String, double> pixels) {
    if (i == 0) {
      return const Offset(0, 0);
    }

    final sum = _getSumOfPreviousPixels(pixels, i);

    return Offset(0, sum);
  }

  @override
  Offset getDividerPosition(int i, Map<String, double> pixels) {
    final sum = _getSumOfPreviousPixelsExcludingCurrentDivider(pixels, i);

    return Offset(0, sum);
  }
}

final class _HorizontalLayoutDelegate extends ResizableLayoutDelegate {
  _HorizontalLayoutDelegate({
    required super.children,
    required super.dividers,
    required super.onLayoutComplete,
  }) : super._();

  @override
  BoxConstraints getConstraints(int i, Size size, double dimension) {
    final min = _getChildMin(i) ?? dimension;
    final max = _getChildMax(i) ?? dimension;

    return BoxConstraints(
      minWidth: min,
      maxWidth: max,
      minHeight: size.height,
      maxHeight: size.height,
    );
  }

  @override
  BoxConstraints getShrinkConstraints(int i, Size size) {
    final min = _getChildMin(i) ?? 0.0;
    final max = _getChildMax(i) ?? double.infinity;

    return BoxConstraints(
      minWidth: min,
      maxWidth: max,
      minHeight: size.height,
      maxHeight: size.height,
    );
  }

  @override
  BoxConstraints getDividerConstraints(int i, Size size) {
    final dividerThickness = dividers[i].thickness + dividers[i].padding;

    return BoxConstraints(
      minWidth: dividerThickness,
      maxWidth: dividerThickness,
      minHeight: size.height,
      maxHeight: size.height,
    );
  }

  @override
  double getLayoutPixels(Size size) {
    return size.width;
  }

  @override
  double subtractPixelsFromSize(Size size, double totalPixels) {
    return size.width - totalPixels;
  }

  @override
  Offset getPosition(int i, Map<String, double> pixels) {
    if (i == 0) {
      return const Offset(0, 0);
    }

    final sum = _getSumOfPreviousPixels(pixels, i);

    return Offset(sum, 0);
  }

  @override
  Offset getDividerPosition(int i, Map<String, double> pixels) {
    final sum = _getSumOfPreviousPixelsExcludingCurrentDivider(pixels, i);

    return Offset(sum, 0);
  }
}

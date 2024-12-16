import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/extensions/iterable_ext.dart';
import 'package:flutter_resizable_container/src/layout_key.dart';

typedef OnLayoutCompleteNotifier = void Function(List<double> pixels);

abstract base class ResizableLayoutDelegate extends MultiChildLayoutDelegate {
  ResizableLayoutDelegate._({
    required this.children,
    required this.sizes,
    required this.dividers,
    required this.onLayoutComplete,
  });

  factory ResizableLayoutDelegate.horizontal({
    required List<ResizableChild> children,
    required List<ResizableSize> sizes,
    required List<ResizableDivider> dividers,
    required OnLayoutCompleteNotifier onLayoutComplete,
  }) =>
      _HorizontalLayoutDelegate(
        children: children,
        sizes: sizes,
        dividers: dividers,
        onLayoutComplete: onLayoutComplete,
      );

  factory ResizableLayoutDelegate.vertical({
    required List<ResizableChild> children,
    required List<ResizableSize> sizes,
    required List<ResizableDivider> dividers,
    required OnLayoutCompleteNotifier onLayoutComplete,
  }) =>
      _VerticalLayoutDelegate(
        children: children,
        sizes: sizes,
        dividers: dividers,
        onLayoutComplete: onLayoutComplete,
      );

  final List<ResizableChild> children;
  final List<ResizableSize> sizes;
  final List<ResizableDivider> dividers;
  final OnLayoutCompleteNotifier onLayoutComplete;

  @override
  void performLayout(Size size) {
    final totalPixels = getLayoutPixels(size);
    final Map<String, double> pixels = {};

    // Step 1. Lay out the dividers and read their sizes.
    var totalDividerPixels = 0.0;
    for (var i = 0; i < dividers.length; i++) {
      final key = DividerKey(i);
      final layout = layoutChild(
        key,
        getDividerConstraints(i, size),
      );
      totalDividerPixels += getLayoutPixels(layout);
      pixels[key.key] = getLayoutPixels(layout);
    }

    // Step 2. Lay out "shrink" children and read their size.
    // These widgets require unconstrained space to determine their "natural" size.
    var totalShrinkPixels = 0.0;
    for (var i = 0; i < sizes.length; i++) {
      if (sizes[i].isShrink) {
        final key = ChildKey(i);
        final layout = layoutChild(key, getShrinkConstraints(i, size));
        pixels[key.key] = getLayoutPixels(layout);
        totalShrinkPixels += pixels[key.key]!;
      }
    }

    // Step 3. Calculate the remaining space available for "expand" children.
    // This involves deducting the total pixels used by the dividers and shrink children,
    // (which is why they were laid out first)
    // along with the total space needed for "ratio" and "pixel" children.
    final pixelPixels = _getTotalPixelPixels();
    final flexPixels =
        totalPixels - totalShrinkPixels - totalDividerPixels - pixelPixels;
    final ratioPixels = flexPixels * _getTotalRatioPixels();
    final expandPixels = flexPixels - ratioPixels;
    final pixelsPerFlex = expandPixels / _getTotalFlexCount();

    // Step 4. Lay out each non-"shrink" child and read its size.
    for (var i = 0; i < sizes.length; i++) {
      if (sizes[i].isShrink) {
        continue;
      }

      final key = ChildKey(i);
      final dimension = sizes[i].isPixels
          ? sizes[i].value
          : sizes[i].isRatio
              ? sizes[i].value * ratioPixels
              : pixelsPerFlex * sizes[i].value;

      final layout = layoutChild(key, getConstraints(i, size, dimension));
      pixels[key.key] = getLayoutPixels(layout);
    }

    // Step 5. Position each child and divider.
    for (var i = 0; i < children.length; i++) {
      final childKey = ChildKey(i);

      positionChild(
        childKey,
        getPosition(i, pixels),
      );

      if (i < dividers.length) {
        final dividerKey = DividerKey(i);

        positionChild(
          dividerKey,
          getDividerPosition(i, pixels),
        );
      }
    }

    // Step 6. Read the final sizes of all children and notify the parent.
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

  double _getTotalPixelPixels() {
    return sizes
        .where((size) => size.isPixels)
        .sum((size) => size.value)
        .toDouble();
  }

  double _getTotalRatioPixels() {
    return sizes
        .where((size) => size.isRatio)
        .sum((size) => size.value)
        .toDouble();
  }

  int _getTotalFlexCount() {
    return sizes
        .where((size) => size.isExpand)
        .sum((size) => size.value)
        .toInt();
  }

  List<double> _getFinalSizes(Map<String, double> pixels) {
    final List<double> finalSizes = [];

    for (var i = 0; i < children.length; i++) {
      final childKey = ChildKey(i);
      finalSizes.add(pixels[childKey.key] ?? 0.0);
    }

    return finalSizes;
  }

  double _getSumOfPreviousPixels(Map<String, double> pixels, int i) {
    var sum = 0.0;

    for (var j = 0; j < i; j++) {
      final childKey = ChildKey(j);
      final dividerKey = DividerKey(j);

      sum += pixels[childKey.key] ?? 0.0;
      sum += pixels[dividerKey.key] ?? 0.0;
    }

    return sum;
  }
}

final class _VerticalLayoutDelegate extends ResizableLayoutDelegate {
  _VerticalLayoutDelegate({
    required super.children,
    required super.sizes,
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
    final dividerKey = DividerKey(i);
    final dividerHeight = pixels[dividerKey.key] ?? 0.0;
    final sum = _getSumOfPreviousPixels(pixels, i);
    final height = sum - dividerHeight;

    return Offset(0, height);
  }
}

final class _HorizontalLayoutDelegate extends ResizableLayoutDelegate {
  _HorizontalLayoutDelegate({
    required super.children,
    required super.sizes,
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
    final dividerKey = DividerKey(i);
    final dividerWidth = pixels[dividerKey.key] ?? 0.0;
    final sum = _getSumOfPreviousPixels(pixels, i);
    final width = sum - dividerWidth;

    return Offset(width, 0);
  }
}

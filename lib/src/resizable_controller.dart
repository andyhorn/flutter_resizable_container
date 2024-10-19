import "dart:collection";
import "dart:math";

import 'package:flutter/material.dart';
import "package:flutter_resizable_container/flutter_resizable_container.dart";
import "package:flutter_resizable_container/src/extensions/iterable_ext.dart";
import "package:flutter_resizable_container/src/resizable_size.dart";

/// A controller to provide a programmatic interface to a [ResizableContainer].
class ResizableController with ChangeNotifier {
  double _availableSpace = -1;
  List<double> _sizes = [];
  List<ResizableChild> _children = const [];

  /// The size, in pixels, of each child.
  UnmodifiableListView<double> get sizes => UnmodifiableListView(_sizes);

  /// A list of ratios (proportion of total available space taken) for each child.
  UnmodifiableListView<double> get ratios {
    return UnmodifiableListView([
      for (final size in sizes) ...[
        size / _availableSpace,
      ],
    ]);
  }

  /// Programmatically set the sizes of the children.
  ///
  /// Each child must have a corresponding index in the [values] list.
  /// The value at each index may be a pixel value, a ratio, or "expand".
  ///
  /// Sizes are allocated based on the following hierarchy:
  /// 1. ResizeSize.pixels
  /// 2. ResizeSize.ratio
  /// 3. ResizeSize.expand
  ///
  /// * If the value is a ResizeSize.pixels, the child will be given that size
  /// in logical pixels
  /// * If the value is a ResizeSize.ratio, the child will be given that portion
  /// of the remaining available space, after all ResizeSize.pixel values have
  /// been allocated
  /// * If the value is a ResizeSize.expand, the child will be given the
  /// remaining available space, after all pixel and ratio values have been
  /// allocated
  /// * If there are multiple "expand" values, each child will be given an equal
  /// portion of the remaining available space, after all pixel and ratio values
  /// have been allocated
  ///
  /// For example,
  ///
  /// ```dart
  /// controller.setSizes(const [
  ///   ResizableSize.pixels(100),
  ///   ResizableSize.ratio(0.5),
  ///   ResizableSize.expand(),
  /// ]);
  /// ```
  ///
  /// In this scenario:
  /// * the first child will be given 100 logical pixels of space
  /// * the second child will be given 50% of the remaining available space
  /// * the third child will be given whatever remaining space is left
  ///
  /// This method throws an `ArgumentError` in any of the following scenarios:
  /// * The length of [values] is different from the length of [children]
  /// * The total amount of pixels is greater than the total available space
  /// * The sum of all ratio values exceeds 1.0
  void setSizes(List<ResizableSize> values) {
    if (values.length != _children.length) {
      throw ArgumentError('Must contain a value for every child');
    }

    _sizes = _mapSizesToAvailableSpace(
      resizableSizes: values,
      availableSpace: _availableSpace,
    );

    notifyListeners();
  }

  void _adjustChildSize({
    required int index,
    required double delta,
  }) {
    final adjustedDelta = delta < 0
        ? _getAdjustedReducingDelta(index: index, delta: delta)
        : _getAdjustedIncreasingDelta(index: index, delta: delta);

    _sizes[index] += adjustedDelta;
    _sizes[index + 1] -= adjustedDelta;
    notifyListeners();
  }

  void _setAvailableSpace(double availableSpace) {
    if (availableSpace == _availableSpace) {
      return;
    }

    if (_availableSpace == -1) {
      // Initialize the child sizes and available space, but do not notify
      // listeners; this step only occurs during the initial build, so we do
      // not need to trigger another build
      _initializeChildSizes(availableSpace);
      _availableSpace = availableSpace;
    } else {
      // Update the child sizes to the new space and notify listeners
      _updateChildSizes(availableSpace);
      _availableSpace = availableSpace;
      notifyListeners();
    }
  }

  void _setChildren(List<ResizableChild> children) {
    _children = children;
  }

  void _updateChildren(List<ResizableChild> children) {
    _children = children;
    _initializeChildSizes(_availableSpace);
  }

  void _initializeChildSizes(double availableSpace) {
    _sizes = _getInitialChildSizes(availableSpace);
  }

  List<double> _getInitialChildSizes(double availableSpace) {
    return _mapSizesToAvailableSpace(
      resizableSizes: _children.map((child) => child.size),
      availableSpace: availableSpace,
    );
  }

  List<double> _mapSizesToAvailableSpace({
    required Iterable<ResizableSize> resizableSizes,
    required double availableSpace,
  }) {
    final totalPixels = resizableSizes.totalPixels;
    final totalRatio = resizableSizes.totalRatio;
    final flexCount = resizableSizes.flexCount;

    if (resizableSizes.totalPixels > availableSpace) {
      throw ArgumentError('Size cannot exceed total available space.');
    }

    if (resizableSizes.totalRatio > 1.0) {
      throw ArgumentError('Ratios cannot exceed 1.0');
    }

    final remainingSpace = availableSpace - totalPixels;
    final ratioSpace = remainingSpace * totalRatio;
    final totalFlexSpace = remainingSpace - ratioSpace;
    final flexUnitSpace = totalFlexSpace / max(1, flexCount);

    final sizes = resizableSizes.map(
      (size) => switch (size.type) {
        SizeType.pixels => size.value,
        SizeType.ratio => remainingSpace * size.value,
        SizeType.expand => flexUnitSpace * size.value,
        SizeType.shrink => 0.0,
      },
    );

    return sizes.toList();
  }

  void _updateChildSizes(double availableSpace) {
    final flexCount = _children.map((child) => child.size).flexCount;

    if (flexCount > 0) {
      // If any children are set to expand, adjust them instead of any
      // statically-sized children
      _flexExpandableChildren(
        availableSpace: availableSpace,
        flexCount: flexCount,
      );
    } else {
      // If no children are set to expand, then scale each child uniformly
      _adjustChildrenUniformly(availableSpace);
    }
  }

  void _flexExpandableChildren({
    required double availableSpace,
    required int flexCount,
  }) {
    final delta = availableSpace - _availableSpace;
    final deltaPerExpandable = delta / flexCount;

    for (var i = 0; i < _children.length; i++) {
      if (_children[i].size.isExpand) {
        _sizes[i] += deltaPerExpandable * _children[i].size.value;
      }
    }
  }

  void _adjustChildrenUniformly(double availableSpace) {
    for (var i = 0; i < _children.length; i++) {
      final currentRatio = _sizes[i] / _availableSpace;
      _sizes[i] = currentRatio * availableSpace;
    }
  }

  double _getAdjustedReducingDelta({
    required int index,
    required double delta,
  }) {
    final currentSize = sizes[index];
    final minCurrentSize = _children[index].minSize ?? 0;
    final adjacentSize = sizes[index + 1];
    final maxAdjacentSize = _children[index + 1].maxSize ?? double.infinity;
    final maxCurrentDelta = currentSize - minCurrentSize;
    final maxAdjacentDelta = maxAdjacentSize - adjacentSize;
    final maxDelta = min(maxCurrentDelta, maxAdjacentDelta);

    if (delta.abs() > maxDelta) {
      delta = -maxDelta;
    }

    return delta;
  }

  double _getAdjustedIncreasingDelta({
    required int index,
    required double delta,
  }) {
    final currentSize = sizes[index];
    final maxCurrentSize = _children[index].maxSize ?? double.infinity;
    final adjacentSize = sizes[index + 1];
    final minAdjacentSize = _children[index + 1].minSize ?? 0;
    final maxAvailableSpace = min(maxCurrentSize, _availableSpace);
    final maxCurrentDelta = maxAvailableSpace - currentSize;
    final maxAdjacentDelta = adjacentSize - minAdjacentSize;
    final maxDelta = min(maxCurrentDelta, maxAdjacentDelta);

    if (delta > maxDelta) {
      delta = maxDelta;
    }

    return delta;
  }
}

final class ResizableControllerManager {
  const ResizableControllerManager(this._controller);

  final ResizableController _controller;

  void setAvailableSpace(double availableSpace) {
    _controller._setAvailableSpace(availableSpace);
  }

  void setChildren(List<ResizableChild> children) {
    _controller._setChildren(children);
  }

  void updateChildren(List<ResizableChild> children) {
    _controller._updateChildren(children);
  }

  void adjustChildSize({
    required int index,
    required double delta,
  }) {
    _controller._adjustChildSize(index: index, delta: delta);
  }
}

abstract class ResizableControllerTestHelper {
  const ResizableControllerTestHelper._();

  static List<ResizableChild> getChildren(ResizableController controller) =>
      controller._children;
}

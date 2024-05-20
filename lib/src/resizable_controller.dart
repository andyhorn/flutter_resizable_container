import "dart:collection";
import "dart:math";

import 'package:flutter/material.dart';
import "package:flutter_resizable_container/flutter_resizable_container.dart";
import "package:flutter_resizable_container/src/extensions/iterable_ext.dart";
import "package:flutter_resizable_container/src/resizable_size.dart";

/// A controller to provide a programmatic interface to a [ResizableContainer].
class ResizableController with ChangeNotifier {
  double _availableSpace = -1;
  double _remainingAvailableSpace = 0;
  List<double> _sizes = [];
  List<ResizableChild> _children = const [];

  /// The size, in pixels, of each child, in order.
  UnmodifiableListView<double> get sizes => UnmodifiableListView(_sizes);

  /// Programmatically set the sizes of the children.
  ///
  /// Each child must have a corresponding index in the [values] list.
  /// The value at each index may be a pixel value, a ratio, or `null`.
  ///
  /// * If the value is a pixel value, the child will be given that size.
  /// * If the value is a ratio value, the child will be given that portion of
  /// the remaining available space, after all pixels values have been allocated.
  /// * If the value is `null`, the child will be given the remaining available
  /// space, after all pixel and ratio values have been allocated.
  /// * If there are multiple `null` values, each child will be given an equal
  /// portion of the remaining available space, after all pixel and ratio values
  /// have been allocated.
  ///
  /// For example,
  ///
  /// ```dart
  /// controller.setSizes([
  ///   ResizableSize.pixels(100),
  ///   ResizableSize.ratio(0.5),
  ///   null,
  /// ]);
  /// ```
  ///
  /// In this scenario:
  /// * the first child will be given 100 logical pixels of space
  /// * the second child will be given 50% of the remaining available space
  /// * the third child will be given whatever remaining space is left:
  /// (total space - 100 - (total space * 0.5))
  ///
  /// This method throws an `ArgumentError` in any of the following scenarios:
  /// * The length of [values] is different from the length of [children]
  /// * The total amount of pixels is greater than the total available space
  /// * The sum of all ratio values exceeds 1.0
  void setSizes(List<ResizableSize?> values) {
    if (values.length != _children.length) {
      throw ArgumentError('Must contain a value for every child');
    }

    final totalPixels = values
        .whereType<ResizableSizePixels>()
        .fold(0.0, (sum, size) => sum + size.value);

    if (totalPixels > _availableSpace) {
      throw ArgumentError('Size cannot exceed total available space.');
    }

    final totalRatio = values
        .whereType<ResizableSizeRatio>()
        .fold(0.0, (sum, size) => sum + size.value);

    if (totalRatio > 1.0) {
      throw ArgumentError('Ratios cannot exceed 1.0');
    }

    final remainingSpace = _availableSpace - totalPixels;
    final ratioSpace = remainingSpace * totalRatio;
    final autoSizeSpace = remainingSpace - ratioSpace;
    final nullValueCount = values.nullCount();
    final nullValueSpace = autoSizeSpace == 0 || nullValueCount == 0
        ? 0.0
        : autoSizeSpace / nullValueCount;

    for (var i = 0; i < values.length; i++) {
      _sizes[i] = switch (values[i]) {
        ResizableSizePixels(:final value) => value,
        ResizableSizeRatio(:final value) => remainingSpace * value,
        null => nullValueSpace,
      };
    }

    notifyListeners();
  }

  /// A list of ratios (proportion of total available space taken) for each child.
  UnmodifiableListView<double> get ratios {
    return UnmodifiableListView([
      for (final size in sizes) ...[
        size / _availableSpace,
      ],
    ]);
  }

  /// Set the total available space and recalculate the child sizes.
  void setAvailableSpace(double availableSpace) {
    if (availableSpace == _availableSpace) {
      return;
    }

    if (_availableSpace == -1) {
      _initializeChildSizesForSpace(availableSpace);
    } else {
      _updateChildSizesForNewAvailableSpace(availableSpace);
    }

    _availableSpace = availableSpace;
    notifyListeners();
  }

  /// Configures this [ResizableController] with an initial list of children.
  /// The available space is unknown at this point.
  ///
  /// This should only be used internally.
  void setChildren(List<ResizableChild> children) {
    _children = children;
  }

  /// Updates the list of [children] and re-calculates their sizes.
  ///
  /// This should only be used internally.
  void updateChildren(List<ResizableChild> children) {
    _children = children;
    _initializeChildSizesForSpace(_availableSpace);
  }

  /// Adjust the size of the child widget at [index] by the [delta] amount.
  void adjustChildSize({
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

  void _initializeChildSizesForSpace(double availableSpace) {
    // If the available space is being set for the first time, calculate the
    // child sizes using their "startingSize" values and then apply the
    // auto-sizing and expanding rules
    _sizes = _getInitialChildSizes(availableSpace);

    // Update the remaining available space
    _remainingAvailableSpace = availableSpace - _sizes.sum();

    // Apply auto-sizing
    _applyAutoSizing(_remainingAvailableSpace);

    // Apply expansions
    _applyExpansions(availableSpace);
  }

  List<double> _getInitialChildSizes(double availableSpace) {
    return _children
        .map((child) => _getSize(child.startingSize, availableSpace))
        .toList();
  }

  void _updateChildSizesForNewAvailableSpace(double availableSpace) {
    // If we are updating the available space again, calculate the child sizes
    // based on their current ratios.
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

  double _getSize(ResizableSize? startingSize, double availableSpace) {
    return switch (startingSize) {
      ResizableSizePixels(:final value) => value,
      ResizableSizeRatio(:final value) => value * availableSpace,
      null => 0.0,
    };
  }

  void _applyAutoSizing(double autoSizingSpace) {
    if (autoSizingSpace == 0) {
      return;
    }

    final autoSizeChildren = _children.where(
      (child) => child.startingSize == null,
    );

    if (autoSizeChildren.isEmpty) {
      return;
    }

    final spacePerChild = autoSizingSpace / autoSizeChildren.length;

    for (var i = 0; i < _children.length; i++) {
      if (_children[i].startingSize == null) {
        _sizes[i] = spacePerChild;
      }
    }
  }

  void _applyExpansions(double availableSpace) {
    final sum = _sizes.sum();

    if (sum == availableSpace) {
      return;
    }

    final expandableChildren = _children.where((child) => child.expand);

    if (expandableChildren.isEmpty) {
      return;
    }

    final difference = availableSpace - sum;
    final spacePerChild = difference / expandableChildren.length;

    for (var i = 0; i < _children.length; i++) {
      if (_children[i].expand) {
        _sizes[i] += spacePerChild;
      }
    }
  }
}

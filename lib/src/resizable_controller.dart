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

  /// The sizes in pixels of each child.
  UnmodifiableListView<double> get sizes => UnmodifiableListView(_sizes);

  /// The ratios of all the children, like [ResizableChild.startingRatio].
  UnmodifiableListView<double> get ratios {
    return UnmodifiableListView([
      for (final size in sizes) ...[
        size / _availableSpace,
      ],
    ]);
  }

  /// Set the total available space.
  set availableSpace(double value) {
    if (value == _availableSpace) {
      return;
    }

    if (_availableSpace == -1) {
      _initializeChildSizesForSpace(value);
    } else {
      _updateChildSizesForNewAvailableSpace(value);
    }

    _availableSpace = value;
    notifyListeners();
  }

  /// Programmatically set the ratios on the children. See [ratios] to get their current ratios.
  set ratios(List<double?> values) {
    if (values.length != _children.length) {
      throw ArgumentError('Must contain a ratio for every child');
    }

    if (values.any((value) => value != null && value < 0)) {
      throw ArgumentError.value(values, 'Ratio values cannot be less than 0.');
    }

    if (values.any((value) => value != null && value > 1)) {
      throw ArgumentError.value(values, 'Ratio values cannot exceed 1.0');
    }

    final ratioTotal = values.whereType<double>().sum();

    if (ratioTotal > 1.0) {
      throw ArgumentError('The sum of all ratios cannot not exceed 1.0');
    }

    // Find the "ratio" for each auto-size child
    final unclaimedSpaceRatio = 1.0 - ratioTotal;
    final autoSizeChildCount = values.nullCount();
    final autoSizeRatio = unclaimedSpaceRatio / max(1, autoSizeChildCount);

    // Update the sizes of each child based on its corresponding ratio
    for (var i = 0; i < values.length; i++) {
      _sizes[i] = (values[i] ?? autoSizeRatio) * _availableSpace;
    }

    // Update the remaining available space
    _remainingAvailableSpace = _availableSpace - _sizes.sum();
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

  // get the adjusted delta for reducing the size of the child at [index]
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

  // get the adjusted delta for increasing the size of the child at [index]
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
        sizes[i] += spacePerChild;
      }
    }
  }
}

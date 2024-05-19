import "dart:collection";
import "dart:math";

import 'package:flutter/material.dart';
import "package:flutter_resizable_container/flutter_resizable_container.dart";
import "package:flutter_resizable_container/src/extensions/iterable_ext.dart";
import "package:flutter_resizable_container/src/resizable_starting_size.dart";

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
      _initializeAvailableSpace(value);
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

    final availableSpace = _availableSpace;
    _availableSpace = -1;
    _calculateChildSizes(availableSpace);
    _availableSpace = availableSpace;
  }

  void _calculateChildSizes(double availableSpace) {
    if (_availableSpace == -1) {
      _remainingAvailableSpace = _calculateRemainingAvailableSPace(
        availableSpace,
      );

      _sizes = _calculateSizesBasedOnStartingRatios(availableSpace);
    } else {
      _sizes = _calculateSizesBasedOnCurrentRatios(availableSpace).toList();
    }
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

  void _initializeAvailableSpace(double availableSpace) {
    // If the available space is being set for the first time, calculate the
    // child sizes using their "startingSize" values and then apply the
    // auto-sizing and expanding rules

    // First, calculate the amount of space claimed by the children using the
    // new available space
    final spaceClaimed = _getSpaceClaimed(availableSpace);

    // Update the remaining available space
    _remainingAvailableSpace = availableSpace - spaceClaimed;

    // Apply auto-sizing
    _applyAutoSizing(_remainingAvailableSpace);

    // Apply expansions
    _applyExpansions(availableSpace);
  }

  void _updateChildSizesForNewAvailableSpace(double availableSpace) {
    // If we are updating the available space again, calculate the child sizes
    // based on their current ratios.
    for (var i = 0; i < _children.length; i++) {
      final currentRatio = _sizes[i] / _availableSpace;
      _sizes[i] = currentRatio * availableSpace;
    }
  }

  List<double> _calculateSizesBasedOnStartingRatios(
    double availableSpace,
  ) {
    final autoSizeChildren = _children.where(
      (child) => child.startingSize == null,
    );
    final autoSize = _remainingAvailableSpace / max(autoSizeChildren.length, 1);
    final sizes = _children.map((child) {
      if (child.startingSize == null) {
        return autoSize;
      }

      return _getSize(child.startingSize, availableSpace);
    }).toList();

    final sum = sizes.sum();
    if (sum < availableSpace) {
      final expandableCount = _children.where((child) => child.expand).length;

      if (expandableCount > 0) {
        final difference = availableSpace - sum;
        final spacePerExpandable = difference / expandableCount;

        for (var i = 0; i < _children.length; i++) {
          if (_children[i].expand) {
            sizes[i] += spacePerExpandable;
          }
        }
      }
    }

    return sizes;
  }

  Iterable<double> _calculateSizesBasedOnCurrentRatios(
    double availableSpace,
  ) sync* {
    for (final size in _sizes) {
      yield (size / _availableSpace) * availableSpace;
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

  // calculate the ratio of available space alloted to children without a
  // specified starting ratio.
  double _calculateRemainingAvailableSPace(double availableSpace) {
    final startingSizes = _children.map((datum) => datum.startingSize);

    if (startingSizes.every((startingSize) => startingSize != null)) {
      return 0;
    }

    var takenSpace = 0.0;

    for (final startingSize in startingSizes) {
      takenSpace += _getSize(startingSize, availableSpace);
    }

    final remainingSpace = availableSpace - takenSpace;
    return remainingSpace;
  }

  double _getSpaceClaimed(double availableSpace) {
    final startingSizes = _children.map((child) => child.startingSize);

    final spaceClaimed = startingSizes.fold(0.0, (claimed, startingSize) {
      return claimed + _getSize(startingSize, availableSpace);
    });

    return spaceClaimed;
  }

  double _getSize(ResizableStartingSize? startingSize, double availableSpace) {
    return switch (startingSize) {
      ResizableStartingSizePixels(:final value) => value,
      ResizableStartingSizeRatio(:final value) => value * availableSpace,
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

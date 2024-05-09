import "dart:math";

import 'package:flutter/material.dart';
import "package:flutter_resizable_container/flutter_resizable_container.dart";
import "package:flutter_resizable_container/src/extensions/iterable_ext.dart";

import "utils.dart";

/// A controller to provide a programmatic interface to a [ResizableContainer].
class ResizableController with ChangeNotifier {
  ResizableController({
    required this.data,
  }) {
    final ratioSum = data.map((datum) => datum.startingRatio ?? 0).sum();

    if (ratioSum > 1) {
      throw ArgumentError.value(
        ratioSum,
        'startingRatio',
        'The sum of all startingRatios must be less than or equal to 1.0',
      );
    }
  }

  double _availableSpace = -1;
  double _nullRatioSpace = 0;
  List<double> _sizes = [];

  /// A list of [ResizableChild] objects that control the sizing parameters
  /// for the list of children of a [ResizableContainer].
  final List<ResizableChild> data;

  /// The sizes in pixels of each child.
  List<double> get sizes => _sizes;

  /// Set the total available space.
  set availableSpace(double value) {
    if (value == _availableSpace) {
      return;
    }

    if (_availableSpace == -1) {
      _nullRatioSpace = _calculateSpaceForNullStartingRatios(value);
      _sizes = _calculateSizesBasedOnStartingRatios(value).toList();
    } else {
      _sizes = _calculateSizesBasedOnCurrentRatios(value).toList();
    }

    _availableSpace = value;
    notifyListeners();
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

  /// The ratios of all the children, like [ResizableChild.startingRatio].
  List<double> get ratios => [
        for (final size in sizes) size / _availableSpace,
      ];

  /// Programmatically set the ratios on the children. See [ratios] to get their current ratios.
  set ratios(List<double?> values) {
    if (values.length != data.length) {
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

    final remaining = 1.0 - ratioTotal;
    final nullRatioCount = values.nullCount();

    if (remaining == 0 || nullRatioCount == 0) {
      _nullRatioSpace = 0;
    } else {
      _nullRatioSpace = remaining / nullRatioCount;
    }

    for (var i = 0; i < values.length; i++) {
      _sizes[i] = (values[i] ?? _nullRatioSpace) * _availableSpace;
    }

    notifyListeners();
  }

  Iterable<double> _calculateSizesBasedOnStartingRatios(
    double availableSpace,
  ) sync* {
    for (final datum in data) {
      yield (datum.startingRatio ?? _nullRatioSpace) * availableSpace;
    }
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
    final minCurrentSize = data[index].minSize ?? 0;
    final adjacentSize = sizes[index + 1];
    final maxAdjacentSize = data[index + 1].maxSize ?? double.infinity;
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
    final maxCurrentSize = data[index].maxSize ?? double.infinity;
    final adjacentSize = sizes[index + 1];
    final minAdjacentSize = data[index + 1].minSize ?? 0;
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
  double _calculateSpaceForNullStartingRatios(double availableSpace) {
    final ratios = data.map((datum) => datum.startingRatio);
    final nonNullRatios = ratios.whereType<double>().toList();
    final ratioSum = sum(nonNullRatios).toDouble();
    final remainingRatioSpace = 1.0 - ratioSum;
    final nullRatiosCount = ratios.length - nonNullRatios.length;

    if (nullRatiosCount == 0) {
      return 0.0;
    }

    return remainingRatioSpace / nullRatiosCount;
  }
}

import "dart:collection";
import "dart:math";

import 'package:flutter/material.dart';
import "package:flutter_resizable_container/flutter_resizable_container.dart";
import "package:flutter_resizable_container/src/extensions/num_ext.dart";
import "package:flutter_resizable_container/src/resizable_size.dart";

/// A controller to provide a programmatic interface to a [ResizableContainer].
class ResizableController with ChangeNotifier {
  final _visibleIndices = SplayTreeSet<int>();

  double _availableSpace = -1;
  List<double> _pixels = [];
  List<ResizableSize> _sizes = const [];
  List<ResizableChild> _children = const [];
  bool _needsLayout = false;
  bool _cascadeNegativeDelta = false;

  /// Whether or not the container needs to (re)layout its children.
  bool get needsLayout => _needsLayout;

  /// The physical size, in pixels, of each child.
  UnmodifiableListView<double> get pixels => UnmodifiableListView(
        _visibleIndices.map((i) => _pixels[i]),
      );

  /// The [ResizableSize] of each child.
  UnmodifiableListView<ResizableSize> get sizes => UnmodifiableListView(
        _visibleIndices.map((i) => _sizes[i]),
      );

  /// A list of ratios (proportion of total available space taken) for each child.
  UnmodifiableListView<double> get ratios => UnmodifiableListView(
        _visibleIndices.map((i) => _pixels[i] / _availableSpace),
      );

  /// Update the [ResizableSize] used to control each child.
  ///
  /// The list must contain a value for every child.
  ///
  /// The total pixels must be less than or equal to the available space.
  ///
  /// The total ratio must be less than or equal to 1.0.
  void setSizes(List<ResizableSize> sizes) {
    if (sizes.length != _children.length) {
      throw ArgumentError('Must contain a value for every child');
    }

    final totalPixels =
        sizes.whereType<ResizableSizePixels>().map((size) => size.pixels).sum();

    if (totalPixels > _availableSpace) {
      throw ArgumentError(
        'Total pixels must be less than or equal to available space',
      );
    }

    final totalRatio =
        sizes.whereType<ResizableSizeRatio>().map((size) => size.ratio).sum();

    if (totalRatio > 1.0) {
      throw ArgumentError('Total ratio must be less than or equal to 1.0');
    }

    _sizes = sizes;
    _needsLayout = true;
    notifyListeners();
  }

  bool isVisible(int index) => _visibleIndices.contains(index);

  int _getRawIndex(int visibleIndex) => _visibleIndices.elementAt(visibleIndex);

  void _adjustChildSize({
    required int index,
    required double delta,
  }) {
    final adjustedDelta = delta < 0
        ? _getAdjustedReducingDelta(index: index, delta: delta)
        : _getAdjustedIncreasingDelta(index: index, delta: delta);

    if (adjustedDelta != delta && _cascadeNegativeDelta) {
      // if the current delta cannot be applied AND cascading is enabled
      if (delta < 0) {
        // and the divider is being dragged to the left

        // distribute the delta amongst the visible leftward siblings
        final changes = _distributeDeltaLeft(index: index, delta: delta);

        // apply the distribution outward from the selected index
        for (var i = 0; i < changes.length; i++) {
          var siblingIndex = index - i - 1;

          if (siblingIndex < 0) {
            continue;
          }

          // apply the change to the next visible leftward sibling
          _pixels[_getRawIndex(siblingIndex)] += changes[i];
        }

        // adjust the width of the first visible sibling to the right by the
        // total amount removed from the leftward siblings
        _pixels[_getRawIndex(index + 1)] += changes.sum().abs();
      } else {
        // and the divider is being dragged to the right

        // distribute the delta amongst the rightward siblings
        final changes = _distributeDeltaRight(index: index, delta: delta);

        // apply the distribution outward from the selected index
        for (var i = 0; i < changes.length; i++) {
          final siblingIndex = index + i + 1;

          if (siblingIndex >= _visibleIndices.length) {
            continue;
          }

          // apply the change to the next visible rightward sibling
          _pixels[_getRawIndex(siblingIndex)] += changes[i];
        }

        // adjust the width of the selected index by the
        // total amount removed from the rightward siblings

        _pixels[_getRawIndex(index)] += changes.sum().abs();
      }
    } else {
      // otherwise, apply the adjusted delta to the selected index and its
      // immediate rightward sibling
      _pixels[_getRawIndex(index)] += adjustedDelta;
      _pixels[_getRawIndex(index + 1)] -= adjustedDelta;
    }

    notifyListeners();
  }

  void setChildren(List<ResizableChild> children) {
    _setChildren(children, notify: true);
  }

  void _initChildren(List<ResizableChild> children) {
    _setChildren(children, notify: false);
  }

  void _setChildren(List<ResizableChild> children, {required bool notify}) {
    _children = children;
    _sizes = children.map((child) => child.size).toList();
    _pixels = List.filled(children.length, 0);
    _visibleIndices.clear();

    for (var i = 0; i < children.length; i++) {
      if (children[i].visible) {
        _visibleIndices.add(i);
      }
    }

    _needsLayout = true;

    if (notify) {
      notifyListeners();
    }
  }

  void _setRenderedSizes(List<double> pixels) {
    _pixels = [];

    // set the pixels for the visible children
    //
    // if the child is visible, set its size to the corresponding pixel
    // size and increment the pixel index
    // if the child is not visible, set its size to 0.0
    var pixelIndex = 0;
    for (var i = 0; i < _children.length; i++) {
      if (_visibleIndices.contains(i)) {
        _pixels.add(pixels[pixelIndex]);
        pixelIndex++;
      } else {
        _pixels.add(0.0);
      }
    }

    _needsLayout = false;
    notifyListeners();
  }

  void _setAvailableSpace(double availableSpace) {
    if (_availableSpace == -1) {
      _needsLayout = true;
      _availableSpace = availableSpace;
      return;
    }

    if (availableSpace == _availableSpace) {
      return;
    }

    // Adjust the sizes of all children based on the new available space.
    //
    // Prioritize adjusting "expand" children first. Any remaining change in
    // available space (if the "expand" children have reached 0 or a size
    // constraint) should be uniformly distributed among the remaining
    // non-shrink children, taking into account their minimum & maximum size
    // constraints.
    final delta = _getDelta(availableSpace);

    if (delta == 0.0) {
      _availableSpace = availableSpace;
      return;
    }

    final distributed = _distributeAvailableSpaceDelta(
      delta: delta,
      sizes: _pixels,
    );

    for (var i = 0; i < sizes.length; i++) {
      _pixels[_getRawIndex(i)] += distributed[i];
    }

    _availableSpace = availableSpace;
  }

  double _getDelta(double availableSpace) {
    var delta = availableSpace - _availableSpace;

    if (delta == 0.0) {
      return 0.0;
    }

    if (delta > 0) {
      final minimumNecessarySize = _getMinimumNecessarySize();

      if (minimumNecessarySize >= availableSpace) {
        return 0.0;
      }

      delta = min(delta, availableSpace - minimumNecessarySize);
    }

    return delta;
  }

  double _getMinimumNecessarySize() {
    final minimums = sizes.map((size) => size.min ?? 0.0).toList();
    return minimums.sum();
  }

  List<double> _distributeDeltaRight({
    required int index,
    required double delta,
  }) {
    // get the indices of all visible rightward siblings
    final indices = List.generate(
      _visibleIndices.length - index - 1,
      (i) => index + i + 1,
    );

    // calculate the allowable change for each sibling
    final allowableChanges = [
      for (final index in indices) ...[
        _getAllowableChange(delta: -delta, index: index, sizes: pixels),
      ],
    ];

    var remainingDelta = -delta;

    // for each rightward sibling, starting with the closest and moving out,
    // calculate the "effective" change and subtract it from the remaining delta
    final changes = <double>[];
    for (var i = 0; i < indices.length && remainingDelta != 0.0; i++) {
      final allowableChange = allowableChanges[i];
      final effectiveChange = max(allowableChange, remainingDelta);
      changes.add(effectiveChange);

      remainingDelta -= effectiveChange;
    }

    return changes;
  }

  List<double> _distributeDeltaLeft({
    required int index,
    required double delta,
  }) {
    // get the indices of all leftward siblings
    final indices = List.generate(index, (i) => i);

    // calculate the allowable change for each sibling
    final allowableChanges = [
      for (final index in indices) ...[
        _getAllowableChange(delta: delta, index: index, sizes: pixels),
      ],
    ];

    var remainingDelta = delta;

    // for each leftward sibling, starting with the closest and moving out,
    // calculate the "effective" change and subtract it from the remaining delta
    final changes = <double>[];
    for (var i = indices.length - 1; i >= 0 && remainingDelta != 0.0; i--) {
      final allowableChange = allowableChanges[i];
      final effectiveChange = max(allowableChange, remainingDelta);
      changes.add(effectiveChange);

      remainingDelta -= effectiveChange;
    }

    return changes;
  }

  List<double> _distributeAvailableSpaceDelta({
    required double delta,
    required List<double> sizes,
  }) {
    final indices = List.generate(_visibleIndices.length, (i) => i);
    final changeableIndices = _getChangeableIndices(delta < 0 ? -1 : 1, sizes);

    if (changeableIndices.isEmpty) {
      return List.filled(sizes.length, 0.0);
    }

    final changePerItem = delta / changeableIndices.length;

    final maximums = indices.map((i) {
      if (changeableIndices.contains(i)) {
        return _getAllowableChange(delta: delta, index: i, sizes: sizes);
      }

      return 0.0;
    }).toList();

    final changes = indices.map((index) {
      if (!changeableIndices.contains(index)) {
        return 0.0;
      }

      final max = maximums[index];

      if (max.abs() < changePerItem.abs()) {
        return max;
      }

      return changePerItem;
    }).toList();

    final changesSum = changes.sum();
    final remainingChange = delta - changesSum;

    if (remainingChange.abs() > 0) {
      final adjustedSizes = indices.map(
        (index) => sizes[index] + changes[index],
      );

      final redistributed = _distributeAvailableSpaceDelta(
        delta: remainingChange,
        sizes: adjustedSizes.toList(),
      );

      for (var i = 0; i < changes.length; i++) {
        changes[i] += redistributed[i];
      }
    }

    return changes;
  }

  double _getAllowableChange({
    required double delta,
    required int index,
    required List<double> sizes,
  }) {
    final targetSize = sizes[index] + delta;

    if (delta < 0) {
      final minimumSize = this.sizes[index].min ?? 0;

      if (targetSize <= minimumSize) {
        return minimumSize - sizes[index];
      }

      return delta;
    }

    final maximumSize = this.sizes[index].max ?? double.infinity;

    if (targetSize >= maximumSize) {
      return maximumSize - sizes[index];
    }

    return delta;
  }

  List<int> _getChangeableIndices(int direction, List<double> sizes) {
    final List<int> changeableIndices = [];
    final indices = List.generate(_visibleIndices.length, (i) => i);

    bool shouldAdd(index) {
      final minSize = this.sizes[index].min ?? 0.0;
      final maxSize = this.sizes[index].max ?? double.infinity;

      if (direction < 0 && sizes[index] > minSize) {
        return true;
      } else if (direction > 0 && sizes[index] < maxSize) {
        return true;
      } else {
        return false;
      }
    }

    for (final index in indices) {
      if (this.sizes[index] is! ResizableSizeExpand) {
        continue;
      }

      if (shouldAdd(index)) {
        changeableIndices.add(index);
      }
    }

    if (changeableIndices.isNotEmpty) {
      return changeableIndices;
    }

    for (final index in indices) {
      if (shouldAdd(index)) {
        changeableIndices.add(index);
      }
    }

    return changeableIndices;
  }

  double _getAdjustedReducingDelta({
    required int index,
    required double delta,
  }) {
    final currentSize = pixels[index];
    final minCurrentSize = sizes[index].min ?? 0;
    final adjacentSize = pixels[index + 1];
    final maxAdjacentSize = sizes[index + 1].max ?? double.infinity;
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
    final currentSize = pixels[index];
    final maxCurrentSize = sizes[index].max ?? double.infinity;
    final adjacentSize = pixels[index + 1];
    final minAdjacentSize = sizes[index + 1].min ?? 0;
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

  void adjustChildSize({required int index, required double delta}) {
    _controller._adjustChildSize(index: index, delta: delta);
  }

  void setRenderedSizes(List<double> sizes) {
    _controller._setRenderedSizes(sizes);
  }

  void setAvailableSpace(double availableSpace) {
    _controller._setAvailableSpace(availableSpace);
  }

  void setNeedsLayout() {
    _controller._needsLayout = true;
  }

  void initChildren(List<ResizableChild> children) {
    _controller._initChildren(children);
  }

  void setCascadeNegativeDelta(bool cascadeNegativeDelta) {
    _controller._cascadeNegativeDelta = cascadeNegativeDelta;
  }
}

abstract class ResizableControllerTestHelper {
  const ResizableControllerTestHelper._();

  static List<ResizableChild> getChildren(ResizableController controller) =>
      controller._children;
}

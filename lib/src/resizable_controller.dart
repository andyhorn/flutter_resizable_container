import "dart:async";
import "dart:collection";
import "dart:math";

import 'package:flutter/material.dart';
import "package:flutter_resizable_container/flutter_resizable_container.dart";

/// A controller to provide a programmatic interface to a [ResizableContainer].
class ResizableController with ChangeNotifier {
  double _availableSpace = -1;
  List<double> _pixels = [];
  List<ResizableSize> _sizes = const [];
  List<ResizableChild> _children = const [];
  bool _needsLayout = false;

  bool get needsLayout => _needsLayout;

  /// The size, in pixels, of each child.
  UnmodifiableListView<double> get pixels => UnmodifiableListView(_pixels);

  UnmodifiableListView<ResizableSize> get sizes => UnmodifiableListView(_sizes);

  /// A list of ratios (proportion of total available space taken) for each child.
  UnmodifiableListView<double> get ratios {
    return UnmodifiableListView([
      for (final size in pixels) ...[
        size / _availableSpace,
      ],
    ]);
  }

  void setSizes(List<ResizableSize> sizes) {
    if (sizes.length != _children.length) {
      throw ArgumentError('Must contain a value for every child');
    }

    _sizes = sizes;
    _needsLayout = true;
    notifyListeners();
  }

  void _adjustChildSize({
    required int index,
    required double delta,
  }) {
    final adjustedDelta = delta < 0
        ? _getAdjustedReducingDelta(index: index, delta: delta)
        : _getAdjustedIncreasingDelta(index: index, delta: delta);

    _pixels[index] += adjustedDelta;
    _pixels[index + 1] -= adjustedDelta;
    notifyListeners();
  }

  void setChildren(List<ResizableChild> children) {
    _children = children;
    _sizes = children.map((child) => child.size).toList();
    _pixels = List.filled(children.length, 0);
    _needsLayout = true;
    notifyListeners();
  }

  void _setRenderedSizes(List<double> pixels) {
    _pixels = pixels;
    _needsLayout = false;
    Timer.run(notifyListeners);
  }

  void _setAvailableSpace(double availableSpace) {
    if (_availableSpace == -1) {
      _needsLayout = true;
      _availableSpace = availableSpace;
      return;
    }

    // Adjust the sizes of all children based on the new available space.
    //
    // Prioritize adjusting "expand" children first. Any remaining change in
    // available space (if the "expand" children have reached 0 or a size
    // constraint) should be uniformly distributed among the remaining
    // non-shrink children, taking into account their minimum & maximum size
    // constraints.
    final delta = availableSpace - _availableSpace;
    final distributed = _distributeDelta(
      delta: delta,
      sizes: _pixels,
    );

    for (var i = 0; i < sizes.length; i++) {
      _pixels[i] += distributed[i];
    }

    _availableSpace = availableSpace;
  }

  List<double> _distributeDelta({
    required double delta,
    required List<double> sizes,
  }) {
    final indices = List.generate(_children.length, (i) => i);
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

    final changesSum = changes.fold(0.0, (sum, curr) => sum + curr);
    final remainingChange = delta - changesSum;

    if (remainingChange.abs() > 0) {
      final adjustedSizes = indices.map(
        (index) => sizes[index] + changes[index],
      );

      final redistributed = _distributeDelta(
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
      final minimumSize = _children[index].minSize ?? 0;

      if (targetSize <= minimumSize) {
        return minimumSize - sizes[index];
      }

      return delta;
    }

    final maximumSize = _children[index].maxSize ?? double.infinity;

    if (targetSize >= maximumSize) {
      return maximumSize - sizes[index];
    }

    return delta;
  }

  List<int> _getChangeableIndices(int direction, List<double> sizes) {
    final List<int> indices = [];

    bool shouldAdd(index) {
      final minSize = _children[index].minSize ?? 0.0;
      final maxSize = _children[index].maxSize ?? double.infinity;

      if (direction < 0 && sizes[index] > minSize) {
        return true;
      } else if (direction > 0 && sizes[index] < maxSize) {
        return true;
      } else {
        return false;
      }
    }

    for (final index in List.generate(_children.length, (i) => i)) {
      if (!_children[index].size.isExpand) {
        continue;
      }

      if (shouldAdd(index)) {
        indices.add(index);
      }
    }

    if (indices.isNotEmpty) {
      return indices;
    }

    for (final index in List.generate(_children.length, (i) => i)) {
      if (shouldAdd(index)) {
        indices.add(index);
      }
    }

    return indices;
  }

  double _getAdjustedReducingDelta({
    required int index,
    required double delta,
  }) {
    final currentSize = pixels[index];
    final minCurrentSize = _children[index].minSize ?? 0;
    final adjacentSize = pixels[index + 1];
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
    final currentSize = pixels[index];
    final maxCurrentSize = _children[index].maxSize ?? double.infinity;
    final adjacentSize = pixels[index + 1];
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

  void adjustChildSize({required int index, required double delta}) {
    _controller._adjustChildSize(index: index, delta: delta);
  }

  void setRenderedSizes(List<double> sizes) {
    _controller._setRenderedSizes(sizes);
  }

  void setAvailableSpace(double availableSpace) {
    _controller._setAvailableSpace(availableSpace);
  }
}

// abstract class ResizableControllerTestHelper {
//   const ResizableControllerTestHelper._();

//   static List<ResizableChild> getChildren(ResizableController controller) =>
//       controller._children;
// }

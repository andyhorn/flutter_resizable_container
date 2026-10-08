import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/extensions/num_ext.dart';
import 'package:flutter_resizable_container/src/extensions/resizable_children_ext.dart';
import 'package:flutter_resizable_container/src/layout/expand_sizes.dart';
import 'package:flutter_resizable_container/src/layout/resizable_allocation.dart';

/// The effective [ResizableSize] applied to a hidden child.
const ResizableSize _hiddenSize = ResizableSize.pixels(0, min: 0, max: 0);

/// The slack allowed when validating [ResizableController.setSizes] totals.
///
/// Absorbs floating-point error from even splits (e.g. `998 / 6` six times);
/// it is sub-pixel for both pixel and ratio totals.
const double _sizeTotalTolerance = 1e-6;

/// A controller to provide a programmatic interface to a [ResizableContainer].
class ResizableController with ChangeNotifier {
  double _availableSpace = -1;
  List<double> _pixels = [];
  List<ResizableSize> _sizes = const [];
  List<ResizableChild> _children = const [];
  final Set<int> _hiddenIndices = <int>{};
  final Map<int, ResizableSize> _savedSizes = <int, ResizableSize>{};
  final Map<int, double> _savedPixels = <int, double>{};
  List<double>? _pixelsBeforeHiddenChange;
  bool _needsLayoutFlag = false;
  int _invalidations = 0;
  bool _cascadeNegativeDelta = false;
  Axis? _direction;

  bool get _needsLayout => _needsLayoutFlag;

  // Each invalidation is counted so a rendered-size report measured against an
  // older layout can be told apart from the current one: the flag alone cannot,
  // because it is already set whenever a measurement is taken.
  set _needsLayout(bool value) {
    _needsLayoutFlag = value;
    if (value) {
      _invalidations++;
    }
  }

  /// Whether or not the container needs to (re)layout its children.
  bool get needsLayout => _needsLayout;

  /// The physical size, in pixels, of each child.
  UnmodifiableListView<double> get pixels => UnmodifiableListView(_pixels);

  /// The [ResizableSize] of each child.
  UnmodifiableListView<ResizableSize> get sizes => UnmodifiableListView(_sizes);

  /// A list of ratios (proportion of total available space taken) for each child.
  UnmodifiableListView<double> get ratios {
    return UnmodifiableListView([
      for (final size in pixels) ...[size / _availableSpace],
    ]);
  }

  /// The set of indices of children that are currently hidden.
  Set<int> get hiddenIndices => Set.unmodifiable(_hiddenIndices);

  /// Whether the child at [index] is currently hidden.
  bool isHidden(int index) => _hiddenIndices.contains(index);

  /// Hide the child at [index] and its associated divider.
  ///
  /// The child's size is remembered and restored by [show]. The space it
  /// frees goes to the `expand` children first, then evenly to the others.
  void hide(int index) => setHidden(index, true);

  /// Show the previously-hidden child at [index] and its associated divider.
  ///
  /// The child gets back the size it was dragged to, clamped to its declared
  /// minimum and maximum. It takes space from its siblings only as far as
  /// they can give it up, so it can end up smaller than that. If the child is
  /// not hidden, this is a no-op.
  void show(int index) => setHidden(index, false);

  /// Sets whether the child at [index] is hidden.
  ///
  /// When hiding, the child's current size is saved and the child collapses
  /// to zero, its divider is omitted, and the other children keep their
  /// current sizes while absorbing the freed space. When showing, the saved
  /// size is restored unless [setSizes] replaced it while the child was
  /// hidden, in which case the container lays the children out again.
  void setHidden(int index, bool hidden) {
    _validateIndex(index);

    if (hidden == _hiddenIndices.contains(index)) {
      return;
    }

    final needsLegacyPath =
        _needsLayout || (!hidden && _savedPixels[index] == null);

    if (needsLegacyPath) {
      _setHiddenAndRelayout(index, hidden);
    } else if (hidden) {
      _hideWithDelta(index);
    } else {
      _showWithDelta(index);
    }

    notifyListeners();
  }

  void _setHiddenAndRelayout(int index, bool hidden) {
    if (hidden) {
      _rememberSize(index);
      _sizes = [..._sizes]..[index] = _hiddenSize;
      _hiddenIndices.add(index);
    } else {
      final restored = _savedSizes.remove(index) ?? _children[index].size;
      _sizes = [..._sizes]..[index] = restored;
      _hiddenIndices.remove(index);
    }

    _needsLayout = true;
  }

  void _rememberSize(int index) {
    _savedSizes[index] = _sizes[index];
    // A zero here can mean "shown but not yet re-rendered", so it must not
    // overwrite the width remembered from the last time it was visible.
    if (_pixels[index] > 0) {
      _savedPixels[index] = _pixels[index];
    }
  }

  void _hideWithDelta(int index) {
    _pixelsBeforeHiddenChange = List.of(_pixels);
    _rememberSize(index);
    _sizes = [..._sizes]..[index] = _hiddenSize;
    _pixels[index] = 0;
    _updateHiddenIndex(index, hidden: true);

    _reconcile();
  }

  void _showWithDelta(int index) {
    _pixelsBeforeHiddenChange = List.of(_pixels);
    final savedSize = _savedSizes.remove(index) ?? _children[index].size;
    final savedPixels = _savedPixels[index]!;
    _updateHiddenIndex(index, hidden: false);

    // `_sizes[index]` stays the hidden entry and `_pixels[index]` stays 0
    // while distributing so the shown child is never a donor.
    final lowerBound = savedSize.min ?? 0.0;
    final upperBound = savedSize.max ?? double.infinity;
    final wanted = savedPixels.clamp(lowerBound, upperBound).toDouble();
    // Negative when the shown child's divider reappears and takes space.
    final gap = _availableSpace - _pixels.sum();
    final shortfall = wanted - gap;

    if (shortfall <= 0) {
      _pixels[index] = wanted;
      _reconcile();
    } else {
      final distributed = _distributeAvailableSpaceDelta(
        delta: -shortfall,
        sizes: _pixels,
      );
      _applyDistribution(distributed);
      _pixels[index] = max(0.0, gap - distributed.sum());
    }

    _sizes = [..._sizes]..[index] = savedSize;
  }

  void _reconcile() {
    final delta = _availableSpace - _pixels.sum();

    if (delta == 0.0) {
      return;
    }

    _applyDistribution(
      _distributeAvailableSpaceDelta(delta: delta, sizes: _pixels),
    );
  }

  void _applyDistribution(List<double> distributed) {
    for (var i = 0; i < _pixels.length; i++) {
      _pixels[i] += distributed[i];
    }
  }

  void _updateHiddenIndex(int index, {required bool hidden}) {
    final dividerSpaceBefore = getDividerSpace(_children, _hiddenIndices);
    if (hidden) {
      _hiddenIndices.add(index);
    } else {
      _hiddenIndices.remove(index);
    }
    final dividerSpaceAfter = getDividerSpace(_children, _hiddenIndices);

    // The container only reserves space for visible dividers, so it reports
    // this change on its next build; applying it now makes that report a
    // no-op instead of a second redistribution.
    _availableSpace = _availableSpace + dividerSpaceBefore - dividerSpaceAfter;
  }

  /// Update the [ResizableSize] used to control each child.
  ///
  /// The list must contain a value for every child.
  ///
  /// The total pixels must be less than or equal to the available space.
  ///
  /// The total ratio must be less than or equal to 1.0.
  ///
  /// Sizes provided for currently-hidden indices are remembered and applied
  /// when the child is shown again, replacing the size it was dragged to; the
  /// child remains hidden until [show] is called.
  void setSizes(List<ResizableSize> sizes) {
    if (sizes.length != _children.length) {
      throw ArgumentError('Must contain a value for every child');
    }

    final effective = [
      for (var i = 0; i < sizes.length; i++)
        _hiddenIndices.contains(i) ? _hiddenSize : sizes[i],
    ];

    final totalPixels = effective
        .whereType<ResizableSizePixels>()
        .map((size) => size.pixels)
        .sum();

    if (totalPixels > _availableSpace + _sizeTotalTolerance) {
      throw ArgumentError(
        'Total pixels must be less than or equal to available space',
      );
    }

    final totalRatio = effective
        .whereType<ResizableSizeRatio>()
        .map((size) => size.ratio)
        .sum();

    if (totalRatio > 1.0 + _sizeTotalTolerance) {
      throw ArgumentError('Total ratio must be less than or equal to 1.0');
    }

    for (final index in _hiddenIndices) {
      _savedSizes[index] = sizes[index];
      _savedPixels.remove(index);
    }

    _sizes = effective;
    _needsLayout = true;
    notifyListeners();
  }

  void _validateIndex(int index) {
    if (index < 0 || index >= _children.length) {
      throw RangeError.index(index, _children, 'index');
    }
  }

  void _adjustChildSize({required int index, required double delta}) {
    final adjustedDelta = delta < 0
        ? _getAdjustedReducingDelta(index: index, delta: delta)
        : _getAdjustedIncreasingDelta(index: index, delta: delta);

    if (adjustedDelta != delta && _cascadeNegativeDelta) {
      // if the current delta cannot be applied AND cascading is enabled
      if (delta < 0) {
        // and the divider is being dragged to the left

        // cap the cascaded delta so the right neighbor (the receiver of the
        // freed space) cannot grow past its max constraint
        final maxGrowth = max(
          0.0,
          (_sizes[index + 1].max ?? double.infinity) - _pixels[index + 1],
        );
        final cascadeDelta = -min(delta.abs(), maxGrowth);

        // The selected child may still have room to shrink toward its min,
        // so it gives up space before any sibling to its left does.
        final changes = _distributeDeltaLeft(
          index: index,
          delta: cascadeDelta,
        );

        for (var i = 0; i < changes.length; i++) {
          _pixels[index - i] += changes[i];
        }

        _pixels[index + 1] -= changes.sum();
      } else {
        // and the divider is being dragged to the right

        // cap the cascaded delta so the selected index (the receiver of the
        // freed space) cannot grow past its max constraint
        final maxGrowth = max(
          0.0,
          (_sizes[index].max ?? double.infinity) - _pixels[index],
        );
        final cascadeDelta = min(delta, maxGrowth);

        final changes = _distributeDeltaRight(
          index: index,
          delta: cascadeDelta,
        );

        for (var i = 0; i < changes.length; i++) {
          _pixels[index + i + 1] += changes[i];
        }

        _pixels[index] -= changes.sum();
      }
    } else {
      // otherwise, apply the adjusted delta to the selected index and its
      // immediate rightward sibling
      _pixels[index] += adjustedDelta;
      _pixels[index + 1] -= adjustedDelta;
    }

    notifyListeners();
  }

  /// Replaces the children managed by this controller, resetting every size
  /// to the one declared by its child and clearing any hidden state.
  ///
  /// Listeners are notified synchronously, so this must not be called while
  /// the widget tree is building.
  @Deprecated(
    'Calling this directly desyncs the controller from the '
    'ResizableContainer, whose children are the source of truth. Update the '
    "container's children instead. Will be removed in the next major release.",
  )
  void setChildren(List<ResizableChild> children) {
    _setChildren(children, notify: true);
  }

  void _initChildren(List<ResizableChild> children) {
    if (_children.isNotEmpty && _children.hasSameStructureAs(children)) {
      _updateChildrenInPlace(children);
      return;
    }
    _setChildren(children, notify: false);
  }

  void _setChildren(List<ResizableChild> children, {required bool notify}) {
    _children = children;
    _sizes = children.map((child) => child.size).toList();
    _pixels = List.filled(children.length, 0);
    _hiddenIndices.clear();
    _savedSizes.clear();
    _savedPixels.clear();
    _needsLayout = true;

    if (notify) {
      notifyListeners();
    }
  }

  /// Rebinds [_children] without resetting pixel, hidden, or saved-size state.
  ///
  /// Used when the children list differs only in non-structural ways (e.g. a
  /// new divider config or a new child widget instance) — the declared sizes
  /// and child count are unchanged, so the controller's layout state remains
  /// valid.
  void _updateChildrenInPlace(List<ResizableChild> children) {
    _children = children;
  }

  void _setRenderedSizes(List<double> pixels) {
    _pixels = pixels;
    _needsLayout = false;
    notifyListeners();
  }

  /// Returns whether the available space changed after the initial layout.
  ///
  /// Never notifies, because this runs during layout; the caller is
  /// responsible for notifying once the frame has completed.
  bool _setAvailableSpace(double availableSpace) {
    if (_availableSpace == -1) {
      _needsLayout = true;
      _availableSpace = availableSpace;
      return false;
    }

    if (availableSpace == _availableSpace) {
      return false;
    }

    final delta = _getDelta(availableSpace);

    if (delta == 0.0) {
      _availableSpace = availableSpace;
      return true;
    }

    final distributed = _distributeAvailableSpaceDelta(
      delta: delta,
      sizes: _pixels,
    );

    for (var i = 0; i < _pixels.length; i++) {
      _pixels[i] += distributed[i];
    }

    _availableSpace = availableSpace;
    return true;
  }

  void _notify() => notifyListeners();

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
    final minimums = _sizes.map((size) => size.min ?? 0.0).toList();
    return minimums.sum();
  }

  List<double> _distributeDeltaRight({
    required int index,
    required double delta,
  }) {
    final indices = [for (var i = index + 1; i < _children.length; i++) i];

    final allowableChanges = [
      for (final index in indices) ...[
        _getAllowableChange(delta: -delta, index: index, sizes: _pixels),
      ],
    ];

    var remainingDelta = -delta;

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
    final indices = [for (var i = 0; i <= index; i++) i];

    final allowableChanges = [
      for (final index in indices) ...[
        _getAllowableChange(delta: delta, index: index, sizes: _pixels),
      ],
    ];

    var remainingDelta = delta;

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
    final indices = List.generate(_children.length, (i) => i);
    final changeableIndices = _getChangeableIndices(delta < 0 ? -1 : 1, sizes);

    if (changeableIndices.isEmpty) {
      return List.filled(sizes.length, 0.0);
    }

    final weights = _getWeights(changeableIndices);
    final totalWeight = weights.values.sum();

    final maximums = indices.map((i) {
      if (weights.containsKey(i)) {
        return _getAllowableChange(delta: delta, index: i, sizes: sizes);
      }

      return 0.0;
    }).toList();

    final changes = indices.map((index) {
      final weight = weights[index];

      if (weight == null) {
        return 0.0;
      }

      final max = maximums[index];
      final changePerItem = delta * weight / totalWeight;

      if (max.abs() < changePerItem.abs()) {
        return max;
      }

      return changePerItem;
    }).toList();

    final changesSum = changes.sum();
    final remainingChange = delta - changesSum;

    if (remainingChange.abs() > precisionErrorTolerance) {
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

  Map<int, int> _getWeights(List<int> changeableIndices) {
    final flexWeights = {
      for (final index in changeableIndices) index: flexOf(_sizes[index]),
    };

    // flex 0 is only asserted against, so release builds can reach a zero
    // total weight; split evenly instead of dividing by zero.
    if (flexWeights.values.sum() == 0) {
      return {for (final index in changeableIndices) index: 1};
    }

    return flexWeights;
  }

  double _getAllowableChange({
    required double delta,
    required int index,
    required List<double> sizes,
  }) {
    final targetSize = sizes[index] + delta;

    if (delta < 0) {
      final minimumSize = _sizes[index].min ?? 0;

      // A child already below its min must not report room to grow.
      if (targetSize <= minimumSize) {
        return min(0, minimumSize - sizes[index]);
      }

      return delta;
    }

    final maximumSize = _sizes[index].max ?? double.infinity;

    if (targetSize >= maximumSize) {
      return max(0, maximumSize - sizes[index]);
    }

    return delta;
  }

  List<int> _getChangeableIndices(int direction, List<double> sizes) {
    final indices = List.generate(_children.length, (i) => i);
    final List<int> changeableIndices = [];

    bool shouldAdd(index) {
      final minSize = _sizes[index].min ?? 0.0;
      final maxSize = _sizes[index].max ?? double.infinity;

      if (direction < 0 && sizes[index] > minSize) {
        return true;
      } else if (direction > 0 && sizes[index] < maxSize) {
        return true;
      } else {
        return false;
      }
    }

    for (final index in indices) {
      if (_sizes[index] is! ResizableSizeExpand) {
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
    final minCurrentSize = _sizes[index].min ?? 0;
    final adjacentSize = pixels[index + 1];
    final maxAdjacentSize = _sizes[index + 1].max ?? double.infinity;
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
    final maxCurrentSize = _sizes[index].max ?? double.infinity;
    final adjacentSize = pixels[index + 1];
    final minAdjacentSize = _sizes[index + 1].min ?? 0;
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

  /// Returns whether the available space changed after the initial layout,
  /// in which case listeners have not yet been notified.
  bool setAvailableSpace(double availableSpace) {
    return _controller._setAvailableSpace(availableSpace);
  }

  void notify() => _controller._notify();

  void setNeedsLayout() {
    _controller._needsLayout = true;
  }

  /// A count that changes whenever the controller invalidates its layout.
  int get invalidations => _controller._invalidations;

  /// The rendered size of the child at [index] from just before it was last
  /// hidden, or `null` when it is unknown (never rendered, or its size was
  /// replaced while hidden).
  double? savedPixels(int index) => _controller._savedPixels[index];

  void initChildren(List<ResizableChild> children) {
    _controller._initChildren(children);
  }

  void setChildren(List<ResizableChild> children) {
    _controller._setChildren(children, notify: true);
  }

  /// Rebinds the controller's children list without resetting any layout
  /// state. Use when the new children differ only in non-structural ways
  /// (e.g. divider config or child widget instances).
  void updateChildrenInPlace(List<ResizableChild> children) {
    _controller._updateChildrenInPlace(children);
  }

  /// The children's pixels as they were just before the last hide or show.
  List<double>? get pixelsBeforeHiddenChange =>
      _controller._pixelsBeforeHiddenChange;

  void setCascadeNegativeDelta(bool cascadeNegativeDelta) {
    _controller._cascadeNegativeDelta = cascadeNegativeDelta;
  }

  /// Records the axis the controller's pixels are measured along, and
  /// invalidates the layout when it differs from the previously recorded one.
  void setDirection(Axis direction) {
    final previous = _controller._direction;
    if (previous != null && previous != direction) {
      _controller._needsLayout = true;
    }
    _controller._direction = direction;
  }
}

abstract class ResizableControllerTestHelper {
  const ResizableControllerTestHelper._();

  static List<ResizableChild> getChildren(ResizableController controller) =>
      controller._children;
}

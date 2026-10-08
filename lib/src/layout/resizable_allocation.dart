import 'package:flutter_resizable_container/src/extensions/iterable_ext.dart';
import 'package:flutter_resizable_container/src/extensions/num_ext.dart';
import 'package:flutter_resizable_container/src/resizable_divider.dart';
import 'package:flutter_resizable_container/src/resizable_size.dart';

/// Whether the divider after child [index] collapses because a neighbour is
/// in [hiddenIndices].
bool isDividerHidden(Set<int> hiddenIndices, int index) =>
    hiddenIndices.contains(index) || hiddenIndices.contains(index + 1);

/// Returns alternating child/divider main-axis sizes for a container with
/// [extent] pixels of main-axis space.
///
/// [dividers] holds the configuration of the divider that follows each child
/// except the last. A divider is collapsed to zero when either neighbour is in
/// [hiddenIndices]. [measureShrink] returns the content-driven size of the
/// shrink child at `index`, given the space `cap` still available to it; the
/// result is clamped to the child's min/max.
List<double> allocateSizes({
  required double extent,
  required List<ResizableSize> sizes,
  required List<ResizableDivider> dividers,
  required Set<int> hiddenIndices,
  required double Function(int index, double cap) measureShrink,
}) {
  final dividerSizes = [
    for (var i = 0; i < dividers.length; i++)
      isDividerHidden(hiddenIndices, i)
          ? 0.0
          : dividers[i].thickness + dividers[i].padding,
  ];
  final dividerSpace = dividerSizes.sum();
  final pixelSpace = _pixelsSpace(sizes);
  final shrinkCap = extent - pixelSpace - dividerSpace;

  final shrinkSizes = <int, double>{
    for (var i = 0; i < sizes.length; i++)
      if (sizes[i] is ResizableSizeShrink)
        i: _clamp(measureShrink(i, shrinkCap), sizes[i]),
  };
  final shrinkSpace = shrinkSizes.values.sum();

  final availableRatioSpace = extent - pixelSpace - shrinkSpace - dividerSpace;
  final requiredRatioSpace = _requiredRatioSpace(sizes, availableRatioSpace);
  final takenSpace =
      pixelSpace + shrinkSpace + requiredRatioSpace + dividerSpace;
  final expandSizes = _expandSizes(sizes, extent - takenSpace);

  final result = <double>[];
  for (var i = 0; i < sizes.length; i++) {
    final size = sizes[i];
    final value = switch (size) {
      ResizableSizePixels(:final pixels) => _clamp(pixels, size),
      ResizableSizeRatio(:final ratio) =>
        _clamp(ratio * availableRatioSpace, size),
      ResizableSizeShrink() => shrinkSizes[i] ?? 0.0,
      ResizableSizeExpand() => expandSizes[i]!,
    };
    result.add(value);
    if (i < dividerSizes.length) {
      result.add(dividerSizes[i]);
    }
  }
  return result;
}

double _pixelsSpace(List<ResizableSize> sizes) {
  return [
    for (final size in sizes)
      if (size case ResizableSizePixels(:final pixels)) _clamp(pixels, size),
  ].sum();
}

double _requiredRatioSpace(List<ResizableSize> sizes, double availableSpace) {
  return [
    for (final size in sizes)
      if (size case ResizableSizeRatio(:final ratio))
        _clamp(ratio * availableSpace, size),
  ].sum();
}

Map<int, double> _expandSizes(
    List<ResizableSize> sizes, double availableSpace) {
  int flexAt(int index) => (sizes[index] as ResizableSizeExpand).flex;

  final unfrozen =
      sizes.indicesWhere((size) => size is ResizableSizeExpand).toList();
  final passLimit = unfrozen.length;
  final expandSizes = <int, double>{};
  var remainingSpace = availableSpace;
  var remainingFlex = unfrozen.map(flexAt).sum();

  for (var pass = 0; pass < passLimit; pass++) {
    final passSpace = remainingSpace;
    final passFlex = remainingFlex;
    // flex 0 is only asserted against, so release builds can still get
    // here with passFlex == 0; return 0 instead of the NaN from 0/0.
    double targetAt(int index) =>
        passFlex == 0 ? 0 : passSpace * flexAt(index) / passFlex;

    var totalViolation = 0.0;
    for (final index in unfrozen) {
      final target = targetAt(index);
      totalViolation += _clamp(target, sizes[index]) - target;
    }

    // A NaN violation (unbounded space) matches no violator, so clamp the
    // targets as-is rather than leave them unassigned.
    if (totalViolation == 0 || totalViolation.isNaN) {
      for (final index in unfrozen) {
        expandSizes[index] = _clamp(targetAt(index), sizes[index]);
      }
      return expandSizes;
    }

    for (final index in unfrozen) {
      final target = targetAt(index);
      final clamped = _clamp(target, sizes[index]);
      final isViolator =
          totalViolation > 0 ? clamped > target : clamped < target;

      if (isViolator) {
        expandSizes[index] = clamped;
        remainingSpace -= clamped;
        remainingFlex -= flexAt(index);
      }
    }
    unfrozen.removeWhere(expandSizes.containsKey);
  }

  return expandSizes;
}

double _clamp(double value, ResizableSize size) {
  return value.clamp(size.min ?? 0, size.max ?? double.infinity);
}

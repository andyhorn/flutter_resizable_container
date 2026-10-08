import 'package:flutter_resizable_container/src/extensions/num_ext.dart';
import 'package:flutter_resizable_container/src/layout/expand_sizes.dart';
import 'package:flutter_resizable_container/src/resizable_child.dart';
import 'package:flutter_resizable_container/src/resizable_divider.dart';
import 'package:flutter_resizable_container/src/resizable_size.dart';

/// Whether the divider after child [index] collapses because a neighbour is
/// in [hiddenIndices].
bool isDividerHidden(Set<int> hiddenIndices, int index) =>
    hiddenIndices.contains(index) || hiddenIndices.contains(index + 1);

/// The main-axis extent of the divider after child [index]: zero when
/// collapsed by a hidden neighbour, otherwise its thickness plus padding.
double dividerExtent(
  ResizableDivider divider,
  Set<int> hiddenIndices,
  int index,
) =>
    isDividerHidden(hiddenIndices, index)
        ? 0.0
        : divider.thickness + divider.padding;

/// The total main-axis space taken by the visible dividers between [children].
double getDividerSpace(
  List<ResizableChild> children,
  Set<int> hiddenIndices,
) {
  var total = 0.0;
  for (var i = 0; i < children.length - 1; i++) {
    total += dividerExtent(children[i].divider, hiddenIndices, i);
  }
  return total;
}

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
      dividerExtent(dividers[i], hiddenIndices, i),
  ];
  final dividerSpace = dividerSizes.sum();
  final pixelSpace = _pixelsSpace(sizes);
  final shrinkCap = extent - pixelSpace - dividerSpace;

  final shrinkSizes = <int, double>{
    for (var i = 0; i < sizes.length; i++)
      if (sizes[i] is ResizableSizeShrink)
        i: clampToSize(measureShrink(i, shrinkCap), sizes[i]),
  };
  final shrinkSpace = shrinkSizes.values.sum();

  final availableRatioSpace = extent - pixelSpace - shrinkSpace - dividerSpace;
  final requiredRatioSpace = _requiredRatioSpace(sizes, availableRatioSpace);
  final takenSpace =
      pixelSpace + shrinkSpace + requiredRatioSpace + dividerSpace;
  final expandSizes = getExpandSizes(sizes, extent - takenSpace);

  final result = <double>[];
  for (var i = 0; i < sizes.length; i++) {
    final size = sizes[i];
    final value = switch (size) {
      ResizableSizePixels(:final pixels) => clampToSize(pixels, size),
      ResizableSizeRatio(:final ratio) =>
        clampToSize(ratio * availableRatioSpace, size),
      ResizableSizeShrink() => shrinkSizes[i] ?? 0.0,
      ResizableSizeExpand() => expandSizes[i] ?? 0.0,
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
      if (size case ResizableSizePixels(:final pixels))
        clampToSize(pixels, size),
  ].sum();
}

double _requiredRatioSpace(List<ResizableSize> sizes, double availableSpace) {
  return [
    for (final size in sizes)
      if (size case ResizableSizeRatio(:final ratio))
        clampToSize(ratio * availableSpace, size),
  ].sum();
}

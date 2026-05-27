import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/extensions/iterable_ext.dart';
import 'package:flutter_resizable_container/src/extensions/num_ext.dart';
import 'package:flutter_resizable_container/src/layout/resizable_layout_direction.dart';
import 'package:flutter_resizable_container/src/resizable_size.dart';

typedef _ContainerMixin
    = ContainerRenderObjectMixin<RenderBox, _ResizableLayoutParentData>;
typedef _DefaultsMixin
    = RenderBoxContainerDefaultsMixin<RenderBox, _ResizableLayoutParentData>;

class ResizableLayout extends MultiChildRenderObjectWidget {
  const ResizableLayout({
    super.key,
    required super.children,
    required this.direction,
    required this.onComplete,
    required this.sizes,
    required this.resizableChildren,
    this.hiddenIndices = const <int>{},
    this.livePixels,
  });

  final Axis direction;
  final ValueChanged<List<double>> onComplete;
  final List<ResizableSize> sizes;
  final List<ResizableChild> resizableChildren;
  final Set<int> hiddenIndices;

  /// Source of authoritative per-child pixel sizes. When non-null, the
  /// render object lays out children directly from `livePixels.value` and
  /// subscribes for change notifications so drag updates can trigger
  /// `markNeedsLayout` without rebuilding the widget tree. When `null`, the
  /// render object falls back to resolving [sizes] from the
  /// [ResizableSize] declarations and reports the resolved values via
  /// [onComplete] — used for the initial layout pass and the offstage
  /// measurement pass.
  final ValueListenable<List<double>>? livePixels;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return ResizableLayoutRenderObject(
      layoutDirection: ResizableLayoutDirection.forAxis(direction),
      sizes: sizes,
      onComplete: onComplete,
      resizableChildren: resizableChildren,
      hiddenIndices: hiddenIndices,
      livePixels: livePixels,
      textDirection: Directionality.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    ResizableLayoutRenderObject renderObject,
  ) {
    renderObject
      ..layoutDirection = ResizableLayoutDirection.forAxis(direction)
      ..sizes = sizes
      ..onComplete = onComplete
      ..resizableChildren = resizableChildren
      ..hiddenIndices = hiddenIndices
      ..livePixels = livePixels
      ..textDirection = Directionality.maybeOf(context);
  }
}

class ResizableLayoutRenderObject extends RenderBox
    with _ContainerMixin, _DefaultsMixin {
  ResizableLayoutRenderObject({
    required ResizableLayoutDirection layoutDirection,
    required List<ResizableSize> sizes,
    required ValueChanged<List<double>> onComplete,
    required List<ResizableChild> resizableChildren,
    Set<int> hiddenIndices = const <int>{},
    ValueListenable<List<double>>? livePixels,
    TextDirection? textDirection,
  })  : _layoutDirection = layoutDirection,
        _sizes = sizes,
        _onComplete = onComplete,
        _resizableChildren = resizableChildren,
        _hiddenIndices = hiddenIndices,
        _livePixels = livePixels,
        _textDirection = textDirection;

  ResizableLayoutDirection _layoutDirection;
  List<ResizableSize> _sizes;
  ValueChanged<List<double>> _onComplete;
  List<ResizableChild> _resizableChildren;
  Set<int> _hiddenIndices;
  ValueListenable<List<double>>? _livePixels;
  TextDirection? _textDirection;
  double _currentPosition = 0.0;
  final Map<int, double> _shrinkSizes = {};

  ResizableLayoutDirection get layoutDirection => _layoutDirection;
  List<ResizableSize> get sizes => _sizes;
  ValueChanged<List<double>> get onComplete => _onComplete;
  List<ResizableChild> get resizableChildren => _resizableChildren;
  Set<int> get hiddenIndices => _hiddenIndices;
  ValueListenable<List<double>>? get livePixels => _livePixels;
  TextDirection? get textDirection => _textDirection;

  set textDirection(TextDirection? value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    // RTL reversal only affects horizontal layouts; vertical layouts are
    // unchanged by directionality so a relayout would be wasted work.
    if (_layoutDirection.isHorizontal) {
      markNeedsLayout();
    }
  }

  set livePixels(ValueListenable<List<double>>? value) {
    if (identical(_livePixels, value)) {
      return;
    }
    if (attached) {
      _livePixels?.removeListener(_handleLivePixelsChanged);
      value?.addListener(_handleLivePixelsChanged);
    }
    _livePixels = value;
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _livePixels?.addListener(_handleLivePixelsChanged);
  }

  @override
  void detach() {
    _livePixels?.removeListener(_handleLivePixelsChanged);
    super.detach();
  }

  void _handleLivePixelsChanged() => markNeedsLayout();

  set hiddenIndices(Set<int> hiddenIndices) {
    if (setEquals(_hiddenIndices, hiddenIndices)) {
      return;
    }

    _hiddenIndices = hiddenIndices;
    markNeedsLayout();
  }

  bool _isDividerHidden(int dividerIndex) {
    return _hiddenIndices.contains(dividerIndex) ||
        _hiddenIndices.contains(dividerIndex + 1);
  }

  set layoutDirection(ResizableLayoutDirection layoutDirection) {
    if (_layoutDirection == layoutDirection) {
      return;
    }

    _layoutDirection = layoutDirection;
    markNeedsLayout();
  }

  set sizes(List<ResizableSize> sizes) {
    if (listEquals(_sizes, sizes)) {
      return;
    }

    _sizes = sizes;
    markNeedsLayout();
  }

  set onComplete(ValueChanged<List<double>> onComplete) {
    if (_onComplete == onComplete) {
      return;
    }

    _onComplete = onComplete;
    markNeedsLayout();
  }

  set resizableChildren(List<ResizableChild> resizableChildren) {
    if (listEquals(_resizableChildren, resizableChildren)) {
      return;
    }

    _resizableChildren = resizableChildren;
    markNeedsLayout();
  }

  @override
  void setupParentData(covariant RenderObject child) {
    child.parentData = _ResizableLayoutParentData();
  }

  @override
  void performLayout() {
    _currentPosition = 0.0;
    _shrinkSizes.clear();

    final children = getChildrenAsList();

    if (_canUseLivePixels()) {
      _performLiveLayout(children);
      return;
    }

    final dividerSpace = _getDividerSpace();
    final pixelSpace = _getPixelsSpace();
    final shrinkCap = layoutDirection.getMaxConstraint(constraints) -
        pixelSpace -
        dividerSpace;
    final shrinkSpace = _getShrinkSpace(children, shrinkCap);
    final availableRatioSpace = _getAvailableRatioSpace(
      pixelSpace: pixelSpace,
      shrinkSpace: shrinkSpace,
      dividerSpace: dividerSpace,
    );
    final requiredRatioSpace = _getRequiredRatioSpace(availableRatioSpace);
    final takenSpace = [
      pixelSpace,
      shrinkSpace,
      requiredRatioSpace,
      dividerSpace,
    ].sum();
    final expandDimension = layoutDirection.getMaxConstraint(constraints);
    final expandSpace = expandDimension - takenSpace;
    final expandSizes = _getExpandSizes(expandSpace);

    final List<double> finalSizes = [];
    for (var i = 0; i < childCount; i += 2) {
      final child = children[i];
      final size = sizes[i ~/ 2];
      final constraints = switch (size) {
        ResizableSizeExpand() => layoutDirection.copyConstraintsWith(
            this.constraints,
            expandSizes[i ~/ 2]!.toDouble(),
          ),
        _ => _getChildConstraints(
            size: size,
            index: i ~/ 2,
            availableRatioSpace: availableRatioSpace,
          ),
      };

      final childSize = _layoutChild(child, constraints);
      finalSizes.add(childSize);

      if (i < childCount - 1) {
        final divider = children[i + 1];
        final dividerIndex = i ~/ 2;
        final dividerConstraints = _isDividerHidden(dividerIndex)
            ? BoxConstraints.tight(layoutDirection.getSize(0, constraints))
            : _getDividerConstraints(resizableChildren[dividerIndex].divider);
        final dividerSize = _layoutChild(divider, dividerConstraints);
        finalSizes.add(dividerSize);
      }
    }

    size = constraints.biggest;
    _maybeReverseOffsetsForRtl();
    onComplete(finalSizes);
  }

  bool _canUseLivePixels() {
    final pixels = _livePixels?.value;
    return pixels != null && pixels.length == _resizableChildren.length;
  }

  /// Fast path used when [_livePixels] is present and its value matches the
  /// expected child count. Lays out children directly from those values and
  /// dividers from their static config — no resolution of [ResizableSize]
  /// declarations and no [onComplete] callback, since the pixels are
  /// already authoritative.
  void _performLiveLayout(List<RenderBox> children) {
    final pixels = _livePixels!.value;
    for (var i = 0; i < childCount; i += 2) {
      final childIndex = i ~/ 2;
      final childMainSize = pixels[childIndex];
      final childConstraints = BoxConstraints.tight(
        layoutDirection.getSize(childMainSize, constraints),
      );
      _layoutChild(children[i], childConstraints);

      if (i < childCount - 1) {
        final dividerIndex = childIndex;
        final divider = _resizableChildren[dividerIndex].divider;
        final dividerMainSize = _isDividerHidden(dividerIndex)
            ? 0.0
            : divider.thickness + divider.padding;
        final dividerConstraints = BoxConstraints.tight(
          layoutDirection.getSize(dividerMainSize, constraints),
        );
        _layoutChild(children[i + 1], dividerConstraints);
      }
    }

    size = constraints.biggest;
    _maybeReverseOffsetsForRtl();
  }

  /// Reverses each child's main-axis offset when the layout is horizontal
  /// and the ambient text direction is RTL. The forward layout always
  /// positions children left-to-right; this hook flips them to match
  /// [Flex]'s RTL semantics.
  void _maybeReverseOffsetsForRtl() {
    if (_textDirection != TextDirection.rtl) return;
    if (!_layoutDirection.isHorizontal) return;

    final totalWidth = constraints.maxWidth;
    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as _ResizableLayoutParentData;
      final width = child.size.width;
      parentData.offset = Offset(totalWidth - parentData.offset.dx - width, 0);
      child = parentData.nextSibling;
    }
  }

  Map<int, Decimal> _getExpandSizes(double availableSpace) {
    bool isExpand(ResizableSize size) => size is ResizableSizeExpand;

    var expandIndices = _sizes.indicesWhere(isExpand).toList();

    if (expandIndices.isEmpty) {
      return {};
    }

    final allocatedSpace = Map<int, Decimal>.fromIterable(
      expandIndices,
      value: (_) => Decimal.zero,
    );

    var remainingFlex = _getFlexCount().toDecimal();
    var remainingSpace = availableSpace.toDecimal();
    var shouldContinue = true;

    do {
      var didChange = false;
      final toRemove = <int>[];
      final targetDeltaPerFlex = (remainingSpace / remainingFlex).toDecimal(
        scaleOnInfinitePrecision: 6,
      );

      for (final index in expandIndices) {
        final size = _sizes[index];

        if (size is ResizableSizeExpand) {
          final flex = size.flex.toDecimal();
          final currentValue = allocatedSpace[index] ?? Decimal.zero;
          final targetDelta = targetDeltaPerFlex * flex;
          final targetSize = (currentValue + targetDelta).toDouble();
          final clampedValue = _clamp(targetSize, size).toDecimal();

          if (clampedValue != currentValue) {
            final difference = clampedValue - currentValue;
            remainingSpace -= difference;
            allocatedSpace[index] = clampedValue;
            didChange = true;
          } else {
            remainingFlex -= flex;
            toRemove.add(index);
          }
        }
      }

      expandIndices.removeWhere(toRemove.contains);

      shouldContinue = didChange && remainingFlex > Decimal.zero;
    } while (shouldContinue);

    return allocatedSpace;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  double _getPixelsSpace() {
    final pixels = [
      for (var i = 0; i < sizes.length; i++) ...[
        if (sizes[i] case ResizableSizePixels(:final pixels)) ...[
          _clamp(pixels, sizes[i]),
        ],
      ],
    ];

    return pixels.sum();
  }

  double _getShrinkSpace(List<RenderBox> children, double cap) {
    var total = 0.0;
    for (var i = 0; i < sizes.length; i++) {
      if (sizes[i] is ResizableSizeShrink) {
        final measured = _measureShrink(children[i * 2], cap);
        final clamped = _clamp(measured, sizes[i]);
        _shrinkSizes[i] = clamped;
        total += clamped;
      }
    }
    return total;
  }

  double _measureShrink(RenderBox child, double cap) {
    final size = child.getDryLayout(
      layoutDirection.getShrinkMeasureConstraints(constraints, cap),
    );
    return layoutDirection.getSizeDimension(size);
  }

  double _getDividerSpace() {
    var total = 0.0;
    for (var i = 0; i < resizableChildren.length - 1; i++) {
      if (_isDividerHidden(i)) {
        continue;
      }
      final divider = resizableChildren[i].divider;
      total += divider.thickness + divider.padding;
    }
    return total;
  }

  BoxConstraints _getDividerConstraints(ResizableDivider divider) {
    return BoxConstraints.tight(
      layoutDirection.getSize(divider.thickness + divider.padding, constraints),
    );
  }

  double _getAvailableRatioSpace({
    required double pixelSpace,
    required double shrinkSpace,
    required double dividerSpace,
  }) {
    return layoutDirection.getMaxConstraint(constraints) -
        pixelSpace -
        shrinkSpace -
        dividerSpace;
  }

  double _getRequiredRatioSpace(double availableSpace) {
    final sizes = [
      for (var i = 0; i < this.sizes.length; i++) ...[
        if (this.sizes[i] case ResizableSizeRatio(:final ratio)) ...[
          _clamp(ratio * availableSpace, this.sizes[i]),
        ],
      ],
    ];

    return sizes.sum();
  }

  int _getFlexCount() {
    return sizes.whereType<ResizableSizeExpand>().map((s) => s.flex).sum();
  }

  BoxConstraints _getChildConstraints({
    required ResizableSize size,
    required int index,
    required double availableRatioSpace,
  }) {
    final value = switch (size) {
      ResizableSizePixels(:final pixels) => pixels,
      ResizableSizeRatio(:final ratio) => ratio * availableRatioSpace,
      ResizableSizeShrink() => _shrinkSizes[index] ?? 0,
      ResizableSizeExpand() => throw Exception('Invalid size (expand)'),
    };

    final clampedValue = _clamp(value, size);
    final childSize = layoutDirection.getSize(clampedValue, constraints);
    final childConstraints = BoxConstraints.tight(childSize);

    return childConstraints;
  }

  double _clamp(double value, ResizableSize size) {
    return value.clamp(
      size.min ?? 0,
      size.max ?? double.infinity,
    );
  }

  double _layoutChild(RenderBox child, BoxConstraints constraints) {
    child.layout(constraints, parentUsesSize: true);
    _setChildOffset(child);
    final size = layoutDirection.getSizeDimension(child.size);
    _currentPosition += size;
    return size;
  }

  void _setChildOffset(RenderBox child) {
    final parentData = child.parentData as _ResizableLayoutParentData;
    parentData.offset = layoutDirection.getOffset(_currentPosition);
  }
}

class _ResizableLayoutParentData extends ContainerBoxParentData<RenderBox>
    with ContainerParentDataMixin<RenderBox> {}

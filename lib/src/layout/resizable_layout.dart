import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/extensions/iterable_ext.dart';
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
  });

  final Axis direction;
  final ValueChanged<List<double>> onComplete;
  final List<ResizableSize> sizes;
  final List<ResizableChild> resizableChildren;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return ResizableLayoutRenderObject(
      layoutDirection: ResizableLayoutDirection.forAxis(direction),
      sizes: sizes,
      onComplete: onComplete,
      resizableChildren: resizableChildren,
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
      ..resizableChildren = resizableChildren;
  }
}

class ResizableLayoutRenderObject extends RenderBox
    with _ContainerMixin, _DefaultsMixin {
  ResizableLayoutRenderObject({
    required ResizableLayoutDirection layoutDirection,
    required List<ResizableSize> sizes,
    required ValueChanged<List<double>> onComplete,
    required List<ResizableChild> resizableChildren,
  })  : _layoutDirection = layoutDirection,
        _sizes = sizes,
        _onComplete = onComplete,
        _resizableChildren = resizableChildren;

  ResizableLayoutDirection _layoutDirection;
  List<ResizableSize> _sizes;
  ValueChanged<List<double>> _onComplete;
  List<ResizableChild> _resizableChildren;
  double _currentPosition = 0.0;

  ResizableLayoutDirection get layoutDirection => _layoutDirection;
  List<ResizableSize> get sizes => _sizes;
  ValueChanged<List<double>> get onComplete => _onComplete;
  List<ResizableChild> get resizableChildren => _resizableChildren;

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

    final children = getChildrenAsList();
    final dividerSpace = _getDividerSpace();
    final pixelSpace = _getPixelsSpace();
    final shrinkSpace = _getShrinkSpace(children);
    final availableRatioSpace = _getAvailableRatioSpace(
      pixelSpace: pixelSpace,
      shrinkSpace: shrinkSpace,
      dividerSpace: dividerSpace,
    );
    final requiredRatioSpace = _getRequiredRatioSpace(availableRatioSpace);

    var flexCount = _getFlexCount();
    var remainingExpandSpace = _getExpandSpace(
      pixelSpace: pixelSpace,
      shrinkSpace: shrinkSpace,
      requiredRatioSpace: requiredRatioSpace,
      dividerSpace: dividerSpace,
    );

    final List<double> finalSizes = [];

    for (var i = 0; i < childCount; i += 2) {
      final child = children[i];
      final size = sizes[i ~/ 2];
      final constraints = _getChildConstraints(
        size: size,
        child: child,
        availableRatioSpace: availableRatioSpace,
        expandSpace: remainingExpandSpace,
        flexCount: flexCount,
      );

      final childSize = _layoutChild(child, constraints);
      finalSizes.add(childSize);

      if (size case ResizableSizeExpand(:final flex)) {
        flexCount -= flex;
        remainingExpandSpace -= layoutDirection.getSizeDimension(child.size);
      }

      if (i < childCount - 1) {
        final divider = children[i + 1];
        final dividerSize = _layoutChild(
          divider,
          _getDividerConstraints(resizableChildren[i ~/ 2].divider),
        );
        finalSizes.add(dividerSize);
      }
    }

    size = constraints.biggest;
    onComplete(finalSizes);
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

    return pixels.fold(0.0, (sum, curr) => sum + curr);
  }

  double _getShrinkSpace(List<RenderBox> children) {
    return [
      for (var i = 0; i < sizes.length; i++) ...[
        if (sizes[i] is ResizableSizeShrink) ...[
          _clamp(
            layoutDirection.getMinIntrinsicDimension(children[i * 2]),
            sizes[i],
          ),
        ]
      ],
    ].fold(0.0, (sum, curr) => sum + curr);
  }

  double _getDividerSpace() {
    return resizableChildren
        .take(resizableChildren.length - 1)
        .map((child) => child.divider.thickness + child.divider.padding)
        .sum((x) => x)
        .toDouble();
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
    return layoutDirection.getMaxConstraintDimension(constraints) -
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

    return sizes.fold(0.0, (sum, curr) => sum + curr);
  }

  int _getFlexCount() {
    return sizes
        .whereType<ResizableSizeExpand>()
        .map((s) => s.flex)
        .fold(0, (sum, curr) => sum + curr);
  }

  double _getExpandSpace({
    required double pixelSpace,
    required double shrinkSpace,
    required double requiredRatioSpace,
    required double dividerSpace,
  }) {
    return layoutDirection.getMaxConstraintDimension(constraints) -
        pixelSpace -
        shrinkSpace -
        requiredRatioSpace -
        dividerSpace;
  }

  BoxConstraints _getChildConstraints({
    required ResizableSize size,
    required RenderBox child,
    required double availableRatioSpace,
    required double expandSpace,
    required int flexCount,
  }) {
    final value = switch (size) {
      ResizableSizePixels(:final pixels) => pixels,
      ResizableSizeRatio(:final ratio) => ratio * availableRatioSpace,
      ResizableSizeShrink() => layoutDirection.getMinIntrinsicDimension(child),
      ResizableSizeExpand(:final flex) => flex * (expandSpace / flexCount),
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

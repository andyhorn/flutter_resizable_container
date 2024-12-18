import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
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
    required this.divider,
    required this.onComplete,
    required this.sizes,
    required this.resizableChildren,
  });

  final Axis direction;
  final ResizableDivider divider;
  final ValueChanged<List<double>> onComplete;
  final List<ResizableSize> sizes;
  final List<ResizableChild> resizableChildren;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return ResizableLayoutRenderObject(
      layoutDirection: ResizableLayoutDirection.forAxis(direction),
      divider: divider,
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
      ..divider = divider
      ..sizes = sizes
      ..onComplete = onComplete
      ..resizableChildren = resizableChildren;
  }
}

class ResizableLayoutRenderObject extends RenderBox
    with _ContainerMixin, _DefaultsMixin {
  ResizableLayoutRenderObject({
    required ResizableLayoutDirection layoutDirection,
    required ResizableDivider divider,
    required List<ResizableSize> sizes,
    required ValueChanged<List<double>> onComplete,
    required List<ResizableChild> resizableChildren,
  })  : _layoutDirection = layoutDirection,
        _divider = divider,
        _sizes = sizes,
        _onComplete = onComplete,
        _resizableChildren = resizableChildren;

  ResizableLayoutDirection _layoutDirection;
  ResizableDivider _divider;
  List<ResizableSize> _sizes;
  ValueChanged<List<double>> _onComplete;
  List<ResizableChild> _resizableChildren;
  double _currentPosition = 0.0;

  ResizableLayoutDirection get layoutDirection => _layoutDirection;
  ResizableDivider get divider => _divider;
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

  set divider(ResizableDivider divider) {
    if (_divider == divider) {
      return;
    }

    _divider = divider;
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
    final dividerConstraints = _getDividerConstraints();
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
        resizableChild: resizableChildren[i ~/ 2],
        availableRatioSpace: availableRatioSpace,
        expandSpace: remainingExpandSpace,
        flexCount: flexCount,
      );

      final childSize = _layoutChild(child, constraints);
      finalSizes.add(childSize);

      if (size.type == SizeType.expand) {
        flexCount -= size.value.toInt();
        remainingExpandSpace -= layoutDirection.getSizeDimension(child.size);
      }

      if (i < childCount - 1) {
        final divider = children[i + 1];
        final dividerSize = _layoutChild(divider, dividerConstraints);
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
        if (sizes[i].isPixels) ...[
          _clamp(sizes[i].value, resizableChildren[i]),
        ],
      ],
    ];

    return pixels.fold(0.0, (sum, curr) => sum + curr);
  }

  double _getShrinkSpace(List<RenderBox> children) {
    return [
      for (var i = 0; i < sizes.length; i++) ...[
        if (sizes[i].isShrink) ...[
          _clamp(
            layoutDirection.getMinIntrinsicDimension(children[i * 2]),
            resizableChildren[i],
          ),
        ]
      ],
    ].fold(0.0, (sum, curr) => sum + curr);
  }

  double _getDividerSpace() {
    final dividerThickness = divider.thickness + divider.padding;
    final dividerCount = childCount ~/ 2;
    return dividerThickness * dividerCount;
  }

  BoxConstraints _getDividerConstraints() {
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
        if (this.sizes[i].isRatio) ...[
          _clamp(
            this.sizes[i].value * availableSpace,
            resizableChildren[i],
          ),
        ],
      ],
    ];

    return sizes.fold(0.0, (sum, curr) => sum + curr);
  }

  int _getFlexCount() {
    return sizes
        .where((s) => s.isExpand)
        .map((s) => s.value)
        .fold(0.0, (sum, curr) => sum + curr)
        .toInt();
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
    required ResizableChild resizableChild,
    required RenderBox child,
    required double availableRatioSpace,
    required double expandSpace,
    required int flexCount,
  }) {
    final value = switch (size.type) {
      SizeType.pixels => size.value,
      SizeType.ratio => size.value * availableRatioSpace,
      SizeType.shrink => layoutDirection.getMinIntrinsicDimension(child),
      SizeType.expand => size.value * (expandSpace / flexCount),
    };

    final clampedValue = _clamp(value, resizableChild);
    final childSize = layoutDirection.getSize(clampedValue, constraints);
    final childConstraints = BoxConstraints.tight(childSize);

    return childConstraints;
  }

  double _clamp(double value, ResizableChild resizableChild) {
    return value.clamp(
      resizableChild.minSize ?? 0,
      resizableChild.maxSize ?? double.infinity,
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

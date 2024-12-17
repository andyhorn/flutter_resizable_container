import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_size.dart';

sealed class ResizableLayoutDirectionHelper {
  const ResizableLayoutDirectionHelper._();

  double getMaxConstraintDimension(BoxConstraints constraints);
  double getSizeDimension(Size size);
  Offset getOffset(double currentPosition);
  Size getSize(double value, BoxConstraints constraints);
  double getMinIntrinsicDimension(RenderBox child);
}

class ResizableHorizontalLayoutHelper extends ResizableLayoutDirectionHelper {
  const ResizableHorizontalLayoutHelper() : super._();

  @override
  double getMaxConstraintDimension(BoxConstraints constraints) {
    return constraints.maxWidth;
  }

  @override
  Offset getOffset(double currentPosition) {
    return Offset(currentPosition, 0.0);
  }

  @override
  double getSizeDimension(Size size) {
    return size.width;
  }

  @override
  Size getSize(double value, BoxConstraints constraints) {
    return Size(value, constraints.maxHeight);
  }

  @override
  double getMinIntrinsicDimension(RenderBox child) {
    return child.getMinIntrinsicWidth(double.infinity);
  }
}

class ResizableVerticalLayoutHelper extends ResizableLayoutDirectionHelper {
  const ResizableVerticalLayoutHelper() : super._();

  @override
  double getMaxConstraintDimension(BoxConstraints constraints) {
    return constraints.maxHeight;
  }

  @override
  Offset getOffset(double currentPosition) {
    return Offset(0.0, currentPosition);
  }

  @override
  double getSizeDimension(Size size) {
    return size.height;
  }

  @override
  Size getSize(double value, BoxConstraints constraints) {
    return Size(constraints.maxWidth, value);
  }

  @override
  double getMinIntrinsicDimension(RenderBox child) {
    return child.getMinIntrinsicHeight(double.infinity);
  }
}

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
    return _ResizableLayoutRenderObject(
      direction: direction == Axis.horizontal
          ? const ResizableHorizontalLayoutHelper()
          : const ResizableVerticalLayoutHelper(),
      divider: divider,
      sizes: sizes,
      onComplete: onComplete,
      resizableChildren: resizableChildren,
    );
  }
}

typedef _ContainerMixin
    = ContainerRenderObjectMixin<RenderBox, _ResizableLayoutParentData>;
typedef _DefaultsMixin
    = RenderBoxContainerDefaultsMixin<RenderBox, _ResizableLayoutParentData>;

class _ResizableLayoutRenderObject extends RenderBox
    with _ContainerMixin, _DefaultsMixin {
  _ResizableLayoutRenderObject({
    required this.direction,
    required this.divider,
    required this.sizes,
    required this.onComplete,
    required this.resizableChildren,
  });

  final ResizableLayoutDirectionHelper direction;
  final ResizableDivider divider;
  final List<ResizableSize> sizes;
  final ValueChanged<List<double>> onComplete;
  final List<ResizableChild> resizableChildren;

  var _currentPosition = 0.0;

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
        remainingExpandSpace -= direction.getSizeDimension(child.size);
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
            direction.getMinIntrinsicDimension(children[i * 2]),
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
      direction.getSize(divider.thickness + divider.padding, constraints),
    );
  }

  double _getAvailableRatioSpace({
    required double pixelSpace,
    required double shrinkSpace,
    required double dividerSpace,
  }) {
    return direction.getMaxConstraintDimension(constraints) -
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
    return direction.getMaxConstraintDimension(constraints) -
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
      SizeType.shrink => direction.getMinIntrinsicDimension(child),
      SizeType.expand => size.value * (expandSpace / flexCount),
    };

    final clampedValue = _clamp(value, resizableChild);
    final childSize = direction.getSize(clampedValue, constraints);
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
    final size = direction.getSizeDimension(child.size);
    _currentPosition += size;
    return size;
  }

  void _setChildOffset(RenderBox child) {
    final parentData = child.parentData as _ResizableLayoutParentData;
    parentData.offset = direction.getOffset(_currentPosition);
  }
}

class _ResizableLayoutParentData extends ContainerBoxParentData<RenderBox>
    with ContainerParentDataMixin<RenderBox> {}

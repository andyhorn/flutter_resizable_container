import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_size.dart';

class ResizableLayout extends MultiChildRenderObjectWidget {
  const ResizableLayout({
    super.key,
    required super.children,
    required this.divider,
    required this.onComplete,
    required this.sizes,
    required this.resizableChildren,
  });

  final ResizableDivider divider;
  final ValueChanged<List<double>> onComplete;
  final List<ResizableSize> sizes;
  final List<ResizableChild> resizableChildren;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _ResizableLayoutRenderObject(
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
    required this.divider,
    required this.sizes,
    required this.onComplete,
    required this.resizableChildren,
  });

  final ResizableDivider divider;
  final List<ResizableSize> sizes;
  final ValueChanged<List<double>> onComplete;
  final List<ResizableChild> resizableChildren;

  var _currentXPosition = 0.0;

  @override
  void setupParentData(covariant RenderObject child) {
    child.parentData = _ResizableLayoutParentData();
  }

  @override
  void performLayout() {
    _currentXPosition = 0.0;

    final dividerConstraints = _getDividerConstraints();
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
      final constraints = _getConstraintsForChild(
        size: size,
        child: child,
        resizableChild: resizableChildren[i ~/ 2],
        availableRatioSpace: availableRatioSpace,
        expandSpace: remainingExpandSpace,
        flexCount: flexCount,
      );

      _layoutChild(child, constraints);
      finalSizes.add(child.size.width);

      if (size.type == SizeType.expand) {
        flexCount -= size.value.toInt();
        remainingExpandSpace -= child.size.width;
      }

      if (i < childCount - 1) {
        final divider = children[i + 1];
        _layoutChild(divider, dividerConstraints);
        finalSizes.add(divider.size.width);
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

  BoxConstraints _getConstraintsForChild({
    required ResizableSize size,
    required ResizableChild resizableChild,
    required RenderBox child,
    required double availableRatioSpace,
    required double expandSpace,
    required int flexCount,
  }) {
    final width = switch (size.type) {
      SizeType.pixels => size.value,
      SizeType.ratio => size.value * availableRatioSpace,
      SizeType.shrink => child.getMinIntrinsicWidth(double.infinity),
      SizeType.expand => size.value * (expandSpace / flexCount),
    };

    final constraints = BoxConstraints.tight(
      Size(_clamp(width, resizableChild), this.constraints.maxHeight),
    );

    return constraints;
  }

  void _layoutChild(RenderBox child, BoxConstraints constraints) {
    child.layout(constraints, parentUsesSize: true);
    _setChildOffset(child, _currentXPosition);
    _currentXPosition += child.size.width;
  }

  void _setChildOffset(RenderBox child, double currentXPosition) {
    final parentData = child.parentData as _ResizableLayoutParentData;
    parentData.offset = Offset(currentXPosition, 0.0);
  }

  BoxConstraints _getDividerConstraints() {
    return BoxConstraints.tight(Size(
      divider.thickness + divider.padding,
      constraints.maxHeight,
    ));
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
            children[i * 2].getMinIntrinsicWidth(double.infinity),
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

  double _getAvailableRatioSpace({
    required double pixelSpace,
    required double shrinkSpace,
    required double dividerSpace,
  }) {
    return constraints.maxWidth - pixelSpace - shrinkSpace - dividerSpace;
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
    return constraints.maxWidth -
        pixelSpace -
        shrinkSpace -
        requiredRatioSpace -
        dividerSpace;
  }

  double _clamp(double value, ResizableChild resizableChild) {
    return value.clamp(
      resizableChild.minSize ?? 0,
      resizableChild.maxSize ?? double.infinity,
    );
  }
}

class _ResizableLayoutParentData extends ContainerBoxParentData<RenderBox>
    with ContainerParentDataMixin<RenderBox> {}

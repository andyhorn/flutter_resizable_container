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
  });

  final ResizableDivider divider;
  final ValueChanged<List<double>> onComplete;
  final List<ResizableSize> sizes;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _ResizableLayoutRenderObject(
      divider: divider,
      sizes: sizes,
      onComplete: onComplete,
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
  });

  final ResizableDivider divider;
  final List<ResizableSize> sizes;
  final ValueChanged<List<double>> onComplete;

  var _currentXPosition = 0.0;

  @override
  void setupParentData(covariant RenderObject child) {
    child.parentData = _ResizableLayoutParentData();
  }

  @override
  void performLayout() {
    _currentXPosition = 0.0;

    final children = getChildrenAsList();
    final pixelSpace = _getPixelsSpace();
    final shrinkSpace = _getShrinkSpace(children);
    final dividerSpace = _getDividerSpace();
    final ratioSpace = _getRatioSpace(
      pixelSpace: pixelSpace,
      shrinkSpace: shrinkSpace,
      dividerSpace: dividerSpace,
    );
    final flexCount = _getFlexCount();
    final expandSpace = _getExpandSpace(
      pixelSpace: pixelSpace,
      shrinkSpace: shrinkSpace,
      ratioSpace: ratioSpace,
      dividerSpace: dividerSpace,
    );

    final List<double> finalSizes = [];

    for (var i = 0, j = 1; i < childCount; i += 2, j += 2) {
      final child = children[i];
      final size = sizes[i ~/ 2];
      final constraints = _getConstraintsForChild(
        size: size,
        child: child,
        ratioSpace: ratioSpace,
        expandSpace: expandSpace,
        flexCount: flexCount,
      );

      _layoutChild(child, constraints);
      finalSizes.add(child.size.width);

      if (j < childCount) {
        final divider = children[j];
        final c = BoxConstraints.tight(Size(
          this.divider.thickness + this.divider.padding,
          constraints.maxHeight,
        ));

        _layoutChild(divider, c);
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
    required RenderBox child,
    required double ratioSpace,
    required double expandSpace,
    required int flexCount,
  }) {
    final width = switch (size.type) {
      SizeType.pixels => size.value,
      SizeType.ratio => size.value * ratioSpace,
      SizeType.shrink => child.getMinIntrinsicWidth(double.infinity),
      SizeType.expand => size.value * (expandSpace / flexCount),
    };

    final constraints = BoxConstraints.tight(
      Size(width, this.constraints.maxHeight),
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

  double _getPixelsSpace() {
    return sizes
        .where((s) => s.isPixels)
        .map((s) => s.value)
        .fold(0.0, (sum, curr) => sum + curr);
  }

  double _getShrinkSpace(List<RenderBox> children) {
    return [
      for (var i = 0; i < sizes.length; i++) ...[
        if (sizes[i].isShrink) ...[
          children[i].getMinIntrinsicWidth(double.infinity),
        ]
      ],
    ].fold(0.0, (sum, curr) => sum + curr);
  }

  double _getDividerSpace() {
    final dividerThickness = divider.thickness + divider.padding;
    return dividerThickness * (childCount - 1);
  }

  double _getRatioSpace({
    required double pixelSpace,
    required double shrinkSpace,
    required double dividerSpace,
  }) {
    final totalRatio = sizes
        .where((s) => s.isRatio)
        .map((s) => s.value)
        .fold(0.0, (sum, curr) => sum + curr);

    return totalRatio *
        (constraints.maxWidth - pixelSpace - shrinkSpace - dividerSpace);
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
    required double ratioSpace,
    required double dividerSpace,
  }) {
    return constraints.maxWidth -
        pixelSpace -
        shrinkSpace -
        ratioSpace -
        dividerSpace;
  }
}

class _ResizableLayoutParentData extends ContainerBoxParentData<RenderBox>
    with ContainerParentDataMixin<RenderBox> {}

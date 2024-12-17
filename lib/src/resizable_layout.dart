import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_size.dart';

sealed class ResizableLayoutDirectionHelper {
  BoxConstraints? _constraints;
  double _currentPosition = 0.0;

  double get currentPosition => _currentPosition;

  void adjustCurrentPosition(Size size);

  void reset(BoxConstraints constraints) {
    _constraints = constraints;
    _currentPosition = 0.0;
  }

  BoxConstraints getConstraintsForChild({
    required ResizableSize size,
    required ResizableChild resizableChild,
    required RenderBox child,
    required double availableRatioSpace,
    required double expandSpace,
    required int flexCount,
  });

  BoxConstraints getDividerConstraints(
    BoxConstraints constraints,
    ResizableDivider divider,
  );

  double getMaxConstraintDimension();
  double getSizeDimension(Size size);
  void layoutChild(RenderBox child, BoxConstraints constraints);
  void setChildOffset(RenderBox child);

  double _clamp(double value, ResizableChild resizableChild) {
    return value.clamp(
      resizableChild.minSize ?? 0,
      resizableChild.maxSize ?? double.infinity,
    );
  }
}

class ResizableHorizontalLayoutHelper extends ResizableLayoutDirectionHelper {
  @override
  void adjustCurrentPosition(Size size) {
    _currentPosition += size.width;
  }

  @override
  BoxConstraints getConstraintsForChild({
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
      Size(_clamp(width, resizableChild), _constraints!.maxHeight),
    );

    return constraints;
  }

  @override
  BoxConstraints getDividerConstraints(
    BoxConstraints constraints,
    ResizableDivider divider,
  ) {
    return BoxConstraints.tight(Size(
      divider.thickness + divider.padding,
      constraints.maxHeight,
    ));
  }

  @override
  double getMaxConstraintDimension() {
    return _constraints!.maxWidth;
  }

  @override
  void layoutChild(RenderBox child, BoxConstraints constraints) {
    child.layout(constraints, parentUsesSize: true);
    setChildOffset(child);
    adjustCurrentPosition(child.size);
  }

  @override
  void setChildOffset(RenderBox child) {
    final parentData = child.parentData as _ResizableLayoutParentData;
    parentData.offset = Offset(currentPosition, 0.0);
  }

  @override
  double getSizeDimension(Size size) {
    return size.width;
  }
}

class ResizableVerticalLayoutHelper extends ResizableLayoutDirectionHelper {
  @override
  void adjustCurrentPosition(Size size) {
    _currentPosition += size.height;
  }

  @override
  BoxConstraints getConstraintsForChild({
    required ResizableSize size,
    required ResizableChild resizableChild,
    required RenderBox child,
    required double availableRatioSpace,
    required double expandSpace,
    required int flexCount,
  }) {
    final height = switch (size.type) {
      SizeType.pixels => size.value,
      SizeType.ratio => size.value * availableRatioSpace,
      SizeType.shrink => child.getMinIntrinsicHeight(double.infinity),
      SizeType.expand => size.value * (expandSpace / flexCount),
    };

    final constraints = BoxConstraints.tight(
      Size(_constraints!.maxWidth, _clamp(height, resizableChild)),
    );

    return constraints;
  }

  @override
  BoxConstraints getDividerConstraints(
    BoxConstraints constraints,
    ResizableDivider divider,
  ) {
    return BoxConstraints.tight(Size(
      constraints.maxWidth,
      divider.thickness + divider.padding,
    ));
  }

  @override
  double getMaxConstraintDimension() {
    return _constraints!.maxHeight;
  }

  @override
  void layoutChild(RenderBox child, BoxConstraints constraints) {
    child.layout(constraints, parentUsesSize: true);
    setChildOffset(child);
    adjustCurrentPosition(child.size);
  }

  @override
  void setChildOffset(RenderBox child) {
    final parentData = child.parentData as _ResizableLayoutParentData;
    parentData.offset = Offset(0.0, currentPosition);
  }

  @override
  double getSizeDimension(Size size) {
    return size.height;
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
          ? ResizableHorizontalLayoutHelper()
          : ResizableVerticalLayoutHelper(),
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

  @override
  void setupParentData(covariant RenderObject child) {
    child.parentData = _ResizableLayoutParentData();
  }

  @override
  void performLayout() {
    direction.reset(constraints);

    final children = getChildrenAsList();
    final dividerSpace = _getDividerSpace();
    final dividerConstraints = direction.getDividerConstraints(
      constraints,
      divider,
    );

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
      final constraints = direction.getConstraintsForChild(
        size: size,
        child: child,
        resizableChild: resizableChildren[i ~/ 2],
        availableRatioSpace: availableRatioSpace,
        expandSpace: remainingExpandSpace,
        flexCount: flexCount,
      );

      direction.layoutChild(child, constraints);
      finalSizes.add(direction.getSizeDimension(child.size));

      if (size.type == SizeType.expand) {
        flexCount -= size.value.toInt();
        remainingExpandSpace -= direction.getSizeDimension(child.size);
      }

      if (i < childCount - 1) {
        final divider = children[i + 1];
        direction.layoutChild(divider, dividerConstraints);
        finalSizes.add(direction.getSizeDimension(divider.size));
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
    return direction.getMaxConstraintDimension() -
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
    return direction.getMaxConstraintDimension() -
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

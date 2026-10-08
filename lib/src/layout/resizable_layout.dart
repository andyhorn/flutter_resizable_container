import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/layout/resizable_allocation.dart';
import 'package:flutter_resizable_container/src/layout/resizable_layout_direction.dart';

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
    this.fixedSizes,
  });

  /// Full alternating child/divider main-axis sizes. When `null` the layout
  /// resolves [sizes] itself and reports the result through [onComplete];
  /// otherwise children are laid out at exactly these sizes and [onComplete]
  /// is never called.
  final List<double>? fixedSizes;

  final Axis direction;
  final ValueChanged<List<double>> onComplete;
  final List<ResizableSize> sizes;
  final List<ResizableChild> resizableChildren;
  final Set<int> hiddenIndices;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return ResizableLayoutRenderObject(
      layoutDirection: ResizableLayoutDirection.forAxis(direction),
      sizes: sizes,
      onComplete: onComplete,
      resizableChildren: resizableChildren,
      hiddenIndices: hiddenIndices,
      fixedSizes: fixedSizes,
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
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
      ..fixedSizes = fixedSizes
      ..textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
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
    List<double>? fixedSizes,
    TextDirection textDirection = TextDirection.ltr,
  })  : _fixedSizes = fixedSizes,
        _textDirection = textDirection,
        _layoutDirection = layoutDirection,
        _sizes = sizes,
        _onComplete = onComplete,
        _resizableChildren = resizableChildren,
        _hiddenIndices = hiddenIndices;

  ResizableLayoutDirection _layoutDirection;
  List<ResizableSize> _sizes;
  ValueChanged<List<double>> _onComplete;
  List<ResizableChild> _resizableChildren;
  Set<int> _hiddenIndices;
  List<double>? _fixedSizes;
  TextDirection _textDirection;

  ResizableLayoutDirection get layoutDirection => _layoutDirection;
  List<ResizableSize> get sizes => _sizes;
  ValueChanged<List<double>> get onComplete => _onComplete;
  List<ResizableChild> get resizableChildren => _resizableChildren;
  Set<int> get hiddenIndices => _hiddenIndices;
  List<double>? get fixedSizes => _fixedSizes;
  TextDirection get textDirection => _textDirection;

  set fixedSizes(List<double>? fixedSizes) {
    if (listEquals(_fixedSizes, fixedSizes)) {
      return;
    }

    _fixedSizes = fixedSizes;
    markNeedsLayout();
  }

  set textDirection(TextDirection textDirection) {
    if (_textDirection == textDirection) {
      return;
    }

    _textDirection = textDirection;
    markNeedsLayout();
  }

  set hiddenIndices(Set<int> hiddenIndices) {
    if (setEquals(_hiddenIndices, hiddenIndices)) {
      return;
    }

    _hiddenIndices = hiddenIndices;
    markNeedsLayout();
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
    final children = getChildrenAsList();
    final fixedSizes = _fixedSizes;
    final usable = fixedSizes != null && fixedSizes.length == children.length;
    final measuring = !usable;
    final fullSizes = usable ? fixedSizes : _allocate(children);

    size = constraints.biggest;

    var position = 0.0;
    final laidOutSizes = <double>[];
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      child.layout(
        BoxConstraints.tight(
            layoutDirection.getSize(fullSizes[i], constraints)),
        parentUsesSize: true,
      );
      final extent = layoutDirection.getSizeDimension(child.size);
      final parentData = child.parentData as _ResizableLayoutParentData;
      parentData.offset = _getChildOffset(position, extent);
      position += extent;
      laidOutSizes.add(extent);
    }

    if (measuring) {
      onComplete(laidOutSizes);
    }
  }

  List<double> _allocate(List<RenderBox> children) {
    return allocateSizes(
      extent: layoutDirection.getMaxConstraint(constraints),
      sizes: sizes,
      dividers: [
        for (var i = 0; i < resizableChildren.length - 1; i++)
          resizableChildren[i].divider,
      ],
      hiddenIndices: hiddenIndices,
      measureShrink: (index, cap) => _measureShrink(children[index * 2], cap),
    );
  }

  Offset _getChildOffset(double position, double extent) {
    return switch (textDirection) {
      TextDirection.ltr => layoutDirection.getOffset(position),
      TextDirection.rtl => layoutDirection.getRtlOffset(position, extent, size),
    };
  }

  double _measureShrink(RenderBox child, double cap) {
    final size = child.getDryLayout(
      layoutDirection.getShrinkMeasureConstraints(constraints, cap),
    );
    return layoutDirection.getSizeDimension(size);
  }

  bool _hasExtent(RenderBox child) {
    return layoutDirection.getSizeDimension(child.size) > 0;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as _ResizableLayoutParentData;
      if (_hasExtent(child)) {
        context.paintChild(child, parentData.offset + offset);
      }
      child = parentData.nextSibling;
    }
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    var child = firstChild;
    while (child != null) {
      if (_hasExtent(child)) visitor(child);
      child = (child.parentData! as _ResizableLayoutParentData).nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}

class _ResizableLayoutParentData extends ContainerBoxParentData<RenderBox>
    with ContainerParentDataMixin<RenderBox> {}

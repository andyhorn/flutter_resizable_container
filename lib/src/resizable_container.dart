import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/src/resizable_child_data.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';

class ResizableContainer extends StatefulWidget {
  const ResizableContainer._create({
    required this.children,
    required this.direction,
    required this.showDivider,
  });

  factory ResizableContainer({
    required Axis direction,
    required List<ResizableChildData> children,
    bool showDivider = true,
  }) {
    final totalRatio =
        children.fold<double>(0.0, (sum, child) => sum += child.startingRatio);

    assert(totalRatio == 1.0);

    return ResizableContainer._create(
      children: children,
      direction: direction,
      showDivider: showDivider,
    );
  }

  final Axis direction;
  final List<ResizableChildData> children;
  final bool showDivider;

  @override
  State<ResizableContainer> createState() => _ResizableContainerState();
}

class _ResizableContainerState extends State<ResizableContainer> {
  final List<double> sizes = [];

  @override
  void didUpdateWidget(covariant ResizableContainer oldWidget) {
    if (oldWidget.direction != widget.direction) {
      sizes.clear();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableSpace = _getAvailableSpace(constraints);

        if (sizes.isEmpty) {
          for (var i = 0; i < widget.children.length; i++) {
            final size = widget.children[i].startingRatio * availableSpace;
            sizes.add(size);
          }
        }

        return Flex(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          direction: widget.direction,
          children: [
            for (var i = 0; i < widget.children.length; i++) ...[
              // build the child
              Builder(
                builder: (context) {
                  final height = _getChildSize(
                    index: i,
                    direction: Axis.vertical,
                    constraints: constraints,
                  );

                  final width = _getChildSize(
                    index: i,
                    direction: Axis.horizontal,
                    constraints: constraints,
                  );

                  return SizedBox(
                    height: height,
                    width: width,
                    child: widget.children[i].child,
                  );
                },
              ),
              if (i < widget.children.length - 1) ...[
                ResizableContainerDivider(
                  direction: widget.direction,
                  onResizeUpdate: (delta) => _handleChildResize(
                    index: i,
                    delta: delta,
                    availableSpace: availableSpace,
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  double _getAvailableSpace(BoxConstraints constraints) {
    final totalSpace = widget.direction == Axis.horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;
    final dividerSpace =
        (widget.children.length - 1) * ResizableContainerDivider.dividerWidth;
    return totalSpace - dividerSpace;
  }

  double? _getChildSize({
    required int index,
    required Axis direction,
    required BoxConstraints constraints,
  }) {
    return direction != widget.direction
        ? _getConstraint(
            constraint: constraints,
            direction: widget.direction,
          )
        : sizes[index];
  }

  double _getConstraint({
    required BoxConstraints constraint,
    required Axis direction,
  }) {
    return direction == Axis.vertical
        ? constraint.maxHeight
        : constraint.maxWidth;
  }

  void _handleChildResize({
    required int index,
    required double delta,
    required double availableSpace,
  }) {
    var newChildSize = _getConstrainedChildSize(index, sizes[index] + delta);
    var newAdjacentChildSize = sizes[index + 1] + (-1 * delta);

    if (_isTooBig(index + 1, newAdjacentChildSize)) {
      // adjacent child exceeds its maximum size constraint
      final maxAdjacentChildSize = _getMaxSize(index + 1)!;
      final difference = newAdjacentChildSize - maxAdjacentChildSize;

      newChildSize += difference;
      newAdjacentChildSize -= difference;
    } else if (_isTooSmall(index + 1, newAdjacentChildSize)) {
      // adjacent child does not meet its minimum size constraint
      final minAdjacentChildSize = _getMinSize(index + 1)!;
      final difference = minAdjacentChildSize - newAdjacentChildSize;

      newChildSize -= difference;
      newAdjacentChildSize += difference;
    }

    final childChanged = newChildSize != sizes[index];
    final adjacentChildChanged = newAdjacentChildSize != sizes[index + 1];

    if (!childChanged && !adjacentChildChanged) {
      // if the sizes haven't changed due to their constraints, do not
      // trigger an unnecessary rebuild
      return;
    }

    if (newChildSize + newAdjacentChildSize > availableSpace) {
      final difference = (newChildSize + newAdjacentChildSize) - availableSpace;
      newChildSize -= (difference / 2);
      newAdjacentChildSize -= (difference / 2);
    }

    setState(() {
      sizes[index] = newChildSize;
      sizes[index + 1] = newAdjacentChildSize;
    });
  }

  double _getConstrainedChildSize(int index, double newSize) {
    if (_isTooSmall(index, newSize)) {
      return _getMinSize(index)!;
    }

    if (_isTooBig(index, newSize)) {
      return _getMaxSize(index)!;
    }

    return newSize;
  }

  bool _isTooSmall(int index, double size) {
    if (size < 0) {
      return true;
    }

    if (widget.children[index].minSize == null) {
      return false;
    }

    return widget.children[index].minSize! > size;
  }

  bool _isTooBig(int index, double size) {
    if (widget.children[index].maxSize == null) {
      return false;
    }

    return widget.children[index].maxSize! < size;
  }

  double? _getMinSize(int index) {
    return widget.children[index].minSize ?? 0;
  }

  double? _getMaxSize(int index) {
    return widget.children[index].maxSize;
  }
}

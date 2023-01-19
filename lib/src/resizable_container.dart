import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/src/resizable_child_data.dart';
import 'package:flutter_resizable_container/src/resize_cursor.dart';

class ResizableContainer extends StatefulWidget {
  const ResizableContainer._create({
    required this.children,
    required this.direction,
  });

  factory ResizableContainer({
    required Axis direction,
    required List<ResizableChildData> children,
  }) {
    final totalRatio =
        children.fold<double>(0.0, (sum, child) => sum += child.startingRatio);

    assert(totalRatio == 1.0);

    return ResizableContainer._create(
      children: children,
      direction: direction,
    );
  }

  final Axis direction;
  final List<ResizableChildData> children;

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
            sizes.add(availableSpace * widget.children[i].startingRatio);
          }
        }

        return Stack(
          children: [
            Flex(
              direction: widget.direction,
              children: [
                for (var i = 0; i < widget.children.length; i++)
                  Builder(
                    builder: (context) {
                      final height = _getChildSize(
                        index: i,
                        direction: Axis.vertical,
                      );

                      final width = _getChildSize(
                        index: i,
                        direction: Axis.horizontal,
                      );

                      return SizedBox(
                        height: height,
                        width: width,
                        child: i < widget.children.length - 1
                            ? Stack(
                                children: [
                                  widget.children[i].child,
                                  ResizeCursor(
                                    direction: widget.direction,
                                    onResizeUpdate: (delta) =>
                                        _handleChildResize(
                                      i,
                                      delta,
                                    ),
                                  ),
                                ],
                              )
                            : widget.children[i].child,
                      );
                    },
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  double _getAvailableSpace(BoxConstraints constraints) {
    return widget.direction == Axis.horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;
  }

  double? _getChildSize({
    required int index,
    required Axis direction,
  }) {
    return direction != widget.direction ? null : sizes[index];
  }

  void _handleChildResize(int index, double delta) {
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

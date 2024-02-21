import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/src/resizable_child_data.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_resizable_container/src/resizable_controller.dart';
import 'package:flutter_resizable_container/src/utils.dart';

/// A container that holds multiple child [Widget]s that can be resized.
///
/// Dividing lines will be added between each child. Dragging the dividers
/// will resize the children along the [direction] axis.
class ResizableContainer extends StatefulWidget {
  /// Creates a new [ResizableContainer] with the given [direction] and list
  /// of [children] Widgets.
  ///
  /// The sum of the [children]'s starting ratios must be equal to 1.0.
  ResizableContainer({
    super.key,
    required this.children,
    required this.direction,
    this.dividerColor,
    this.controller,
    this.dividerWidth = 2.0,
  }) : assert(
    sum([for (final child in children) child.startingRatio]) == 1.0,
    'The sum of the children\'s starting ratios must be equal to 1.0.',
  );

  /// The direction along which the child widgets will be laid and resized.
  final Axis direction;

  /// The list of [Widget]s and their sizing information.
  final List<ResizableChildData> children;

  /// The width of the dividers between the children.
  final double dividerWidth;

  /// The color of the dividers between the children.
  ///
  /// If not provided, Theme.of(context).dividerColor will be used.
  final Color? dividerColor;

  /// The controller that will be used to manage programmatic resizing of the children.
  final ResizableController? controller;

  @override
  State<ResizableContainer> createState() => _ResizableContainerState();
}

class _ResizableContainerState extends State<ResizableContainer> {
  late ResizableController controller;
  List<double> get sizes => controller.sizes;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _initController() {
    controller = widget.controller ?? ResizableController();
    controller.addListener(_listener);
  }

  void _disposeController() {
    controller.removeListener(_listener);
  }

  void _listener() => setState(() {});

  @override
  void didUpdateWidget(covariant ResizableContainer oldWidget) {
    _disposeController();
    _initController();
    // If the axis direction has changed, reset and re-calculate the sizes.
    if (oldWidget.direction != widget.direction) {
      sizes.clear();
      final size = MediaQuery.sizeOf(context);
      final availableSpace = _getAvailableSpace(
        BoxConstraints(maxWidth: size.width, maxHeight: size.height),
      );
      _setSizes(availableSpace);
      setState(() {});
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableSpace = _getAvailableSpace(constraints);
        controller.availableSpace = availableSpace;
        if (sizes.isEmpty) {
          _setSizes(availableSpace);
        } else {
          _adjustSizes(availableSpace);
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
                  dividerColor:
                      widget.dividerColor ?? Theme.of(context).dividerColor,
                  dividerWidth: widget.dividerWidth,
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

  void _setSizes(double availableSpace) {
    for (var i = 0; i < widget.children.length; i++) {
      final size = widget.children[i].startingRatio * availableSpace;
      sizes.add(size);
    }
  }

  void _adjustSizes(double availableSpace) {
    final previousSpace = sizes.reduce((total, size) => size + total);
    for (var i = 0; i < widget.children.length; i++) {
      final previousSize = sizes[i];
      final ratio = previousSize / previousSpace;
      final newSize = ratio * availableSpace;
      sizes[i] = newSize;
    }
  }

  double _getAvailableSpace(BoxConstraints constraints) {
    final totalSpace = widget.direction == Axis.horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;
    final dividerSpace = (widget.children.length - 1) * widget.dividerWidth;
    return totalSpace - dividerSpace;
  }

  double _getChildSize({
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
    var newAdjacentChildSize = sizes[index + 1] - delta;

    if (_isTooBig(index + 1, newAdjacentChildSize)) {
      // adjacent child exceeds its maximum size constraint
      final maxAdjacentChildSize = _getMaxSize(index + 1)!;
      final difference = newAdjacentChildSize - maxAdjacentChildSize;

      newChildSize += difference;
      newAdjacentChildSize -= difference;
    } else if (_isTooSmall(index + 1, newAdjacentChildSize)) {
      // adjacent child does not meet its minimum size constraint
      final minAdjacentChildSize = _getMinSize(index + 1);
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

    if (newChildSize < 0) {
      final difference = -1 * newChildSize;
      newChildSize = 0;
      newAdjacentChildSize -= difference;
    } else if (newAdjacentChildSize < 0) {
      final difference = -1 * newAdjacentChildSize;
      newAdjacentChildSize = 0;
      newChildSize -= difference;
    }

    setState(() {
      sizes[index] = newChildSize;
      sizes[index + 1] = newAdjacentChildSize;
    });
  }

  double _getConstrainedChildSize(int index, double newSize) {
    if (_isTooSmall(index, newSize)) {
      return _getMinSize(index);
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

  double _getMinSize(int index) {
    return widget.children[index].minSize ?? 0;
  }

  double? _getMaxSize(int index) {
    return widget.children[index].maxSize;
  }
}

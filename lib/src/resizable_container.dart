import 'dart:math';

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
    this.dividerIndent,
    this.dividerEndIndent,
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

  /// The indent of the divider at its start.
  ///
  /// For dividers running from top-to-bottom, this indents the top.
  /// For dividers running from left-to-right, this indents the left.
  final double? dividerIndent;

  /// The indent of the divider at its end.
  ///
  /// For dividers running from top-to-bottom, this indents the bottom.
  /// For dividers running from left-to-right, this indents the right.
  final double? dividerEndIndent;

  /// The controller that will be used to manage programmatic resizing of the children.
  final ResizableController? controller;

  @override
  State<ResizableContainer> createState() => _ResizableContainerState();
}

class _ResizableContainerState extends State<ResizableContainer> {
  ResizableController? _defaultController;

  ResizableController get controller =>
      widget.controller ?? _defaultController!;

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
    if (widget.controller == null) {
      _defaultController = ResizableController();
    }

    controller.addListener(_listener);
  }

  void _disposeController() {
    controller.removeListener(_listener);
    _defaultController?.dispose();
  }

  void _listener() => setState(() {});

  @override
  void didUpdateWidget(covariant ResizableContainer oldWidget) {
    // If the axis direction has changed, reset and re-calculate the sizes.
    if (oldWidget.direction != widget.direction) {
      _disposeController();
      _initController();
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
    final previousSpace = sum(sizes);
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
    final adjustedDelta = delta < 0
        ? _getAdjustedReducingDelta(
            index: index,
            delta: delta,
          )
        : _getAdjustedIncreasingDelta(
            index: index,
            delta: delta,
            availableSpace: availableSpace,
          );

    sizes[index] += adjustedDelta;
    sizes[index + 1] -= adjustedDelta;

    setState(() {});
  }

  // get the adjusted delta for reducing the size of the child at [index]
  double _getAdjustedReducingDelta({
    required int index,
    required double delta,
  }) {
    final currentSize = sizes[index];
    final minCurrentSize = widget.children[index].minSize;
    final adjacentSize = sizes[index + 1];
    final maxAdjacentSize = widget.children[index + 1].maxSize;
    final maxCurrentDelta = currentSize - (minCurrentSize ?? 0);
    final maxAdjacentDelta =
        (maxAdjacentSize ?? double.infinity) - adjacentSize;
    final maxDelta = min(maxCurrentDelta, maxAdjacentDelta);

    if (delta.abs() > maxDelta) {
      delta = -maxDelta;
    }

    return delta;
  }

  // get the adjusted delta for increasing the size of the child at [index]
  double _getAdjustedIncreasingDelta({
    required int index,
    required double delta,
    required double availableSpace,
  }) {
    final currentSize = sizes[index];
    final maxCurrentSize = widget.children[index].maxSize;
    final adjacentSize = sizes[index + 1];
    final minAdjacentSize = widget.children[index + 1].minSize;
    final maxAvailableSpace =
        min(maxCurrentSize ?? double.infinity, availableSpace);
    final maxCurrentDelta = maxAvailableSpace - currentSize;
    final maxAdjacentDelta = adjacentSize - (minAdjacentSize ?? 0);
    final maxDelta = min(maxCurrentDelta, maxAdjacentDelta);

    if (delta > maxDelta) {
      delta = maxDelta;
    }

    return delta;
  }
}

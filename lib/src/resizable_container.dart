import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/src/extensions/box_constraints_ext.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_resizable_container/src/resizable_controller.dart';

/// A container that holds multiple child [Widget]s that can be resized.
///
/// Dividing lines will be added between each child. Dragging the dividers
/// will resize the children along the [direction] axis.
class ResizableContainer extends StatelessWidget {
  /// Creates a new [ResizableContainer] with the given [direction] and list
  /// of [children] Widgets.
  ///
  /// The sum of the [children]'s starting ratios must be equal to 1.0.
  ResizableContainer({
    super.key,
    required this.children,
    required this.controller,
    required this.direction,
    this.dividerColor,
    this.dividerWidth = 2.0,
    this.dividerIndent,
    this.dividerEndIndent,
  }) : assert(
          children.length == controller.data.length,
          'Controller must have as many data items as there are children.',
        );

  /// A list of resizable [Widget]s.
  final List<Widget> children;

  /// The controller that will be used to manage programmatic resizing of the children.
  final ResizableController controller;

  /// The direction along which the child widgets will be laid and resized.
  final Axis direction;

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        controller.availableSpace = _getAvailableSpace(constraints);

        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Flex(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              direction: direction,
              children: [
                for (var i = 0; i < children.length; i++) ...[
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
                        child: children[i],
                      );
                    },
                  ),
                  if (i < children.length - 1) ...[
                    ResizableContainerDivider(
                      dividerColor:
                          dividerColor ?? Theme.of(context).dividerColor,
                      dividerWidth: dividerWidth,
                      indent: dividerIndent,
                      endIndent: dividerEndIndent,
                      direction: direction,
                      onResizeUpdate: (delta) => controller.adjustChildSize(
                        index: i,
                        delta: delta,
                      ),
                    ),
                  ],
                ],
              ],
            );
          },
        );
      },
    );
  }

  double _getAvailableSpace(BoxConstraints constraints) {
    final totalSpace = constraints.maxForDirection(direction);
    final dividerSpace = (children.length - 1) * dividerWidth;
    return totalSpace - dividerSpace;
  }

  double _getChildSize({
    required int index,
    required Axis direction,
    required BoxConstraints constraints,
  }) {
    return direction != direction
        ? constraints.maxForDirection(direction)
        : controller.sizes[index];
  }
}

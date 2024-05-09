import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/extensions/box_constraints_ext.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';

/// A container that holds multiple child [Widget]s that can be resized.
///
/// Dividing lines will be added between each child. Dragging the dividers
/// will resize the children along the [direction] axis.
class ResizableContainer extends StatefulWidget {
  /// Creates a new [ResizableContainer] with the given [direction] and list
  /// of [children] Widgets.
  ///
  /// The sum of the [children]'s starting ratios must be equal to 1.0.
  const ResizableContainer({
    super.key,
    required this.children,
    required this.controller,
    required this.direction,
    ResizableDivider? divider,
  }) : divider = divider ?? const ResizableDivider();

  /// A list of resizable [Widget]s.
  final List<ResizableChild> children;

  /// The controller that will be used to manage programmatic resizing of the children.
  final ResizableController controller;

  /// The direction along which the child widgets will be laid and resized.
  final Axis direction;

  /// Configuration values for the dividing space/line between this container's [children].
  final ResizableDivider divider;

  @override
  State<ResizableContainer> createState() => _ResizableContainerState();
}

class _ResizableContainerState extends State<ResizableContainer> {
  @override
  void initState() {
    super.initState();

    ResizableControllerManager.setChildren(widget.controller, widget.children);
  }

  @override
  void didUpdateWidget(covariant ResizableContainer oldWidget) {
    if (oldWidget.children.length != widget.children.length) {
      ResizableControllerManager.setChildren(
        widget.controller,
        widget.children,
      );
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        widget.controller.availableSpace = _getAvailableSpace(constraints);

        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
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
                      config: widget.divider,
                      direction: widget.direction,
                      onResizeUpdate: (delta) =>
                          widget.controller.adjustChildSize(
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
    final totalSpace = constraints.maxForDirection(widget.direction);
    final dividerSpace = (widget.children.length - 1) * widget.divider.size;
    return totalSpace - dividerSpace;
  }

  double _getChildSize({
    required int index,
    required Axis direction,
    required BoxConstraints constraints,
  }) {
    return direction != direction
        ? constraints.maxForDirection(direction)
        : widget.controller.sizes[index];
  }
}

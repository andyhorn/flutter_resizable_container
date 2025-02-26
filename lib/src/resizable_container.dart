import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/extensions/box_constraints_ext.dart';
import 'package:flutter_resizable_container/src/extensions/iterable_ext.dart';
import 'package:flutter_resizable_container/src/extensions/num_ext.dart';
import 'package:flutter_resizable_container/src/layout/resizable_layout.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_resizable_container/src/resizable_controller.dart';

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
    required this.direction,
    this.controller,
  });

  /// A list of resizable [ResizableChild] containing the child [Widget]s and
  /// their sizing configuration.
  final List<ResizableChild> children;

  /// The controller that will be used to manage programmatic resizing of the children.
  final ResizableController? controller;

  /// The direction along which the child widgets will be laid and resized.
  final Axis direction;

  @override
  State<ResizableContainer> createState() => _ResizableContainerState();
}

class _ResizableContainerState extends State<ResizableContainer> {
  late final controller = widget.controller ?? ResizableController();
  late final isDefaultController = widget.controller == null;
  late final manager = ResizableControllerManager(controller);

  @override
  void initState() {
    super.initState();

    manager.initChildren(widget.children);
  }

  @override
  void didUpdateWidget(covariant ResizableContainer oldWidget) {
    final didChildrenChange =
        oldWidget.children.length != widget.children.length;
    final didDirectionChange = oldWidget.direction != widget.direction;

    if (didChildrenChange) {
      controller.setChildren(widget.children);
    }

    if (didChildrenChange || didDirectionChange) {
      manager.setNeedsLayout();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    if (isDefaultController) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableSpace = _getAvailableSpace(constraints);
        manager.setAvailableSpace(availableSpace);

        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (controller.needsLayout) {
              return ResizableLayout(
                direction: widget.direction,
                onComplete: (sizes) {
                  final childSizes = sizes.evenIndices().toList();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    manager.setRenderedSizes(childSizes);
                  });
                },
                sizes: controller.sizes,
                resizableChildren: widget.children,
                children: [
                  for (var i = 0; i < widget.children.length; i++) ...[
                    widget.children[i].child,
                    if (i < widget.children.length - 1) ...[
                      ResizableContainerDivider.placeholder(
                        config: widget.children[i].divider,
                        direction: widget.direction,
                      ),
                    ],
                  ],
                ],
              );
            } else {
              return Flex(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                direction: widget.direction,
                children: [
                  for (var i = 0; i < widget.children.length; i++) ...[
                    Builder(
                      builder: (context) {
                        final child = widget.children[i].child;

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
                          child: child,
                        );
                      },
                    ),
                    if (i < widget.children.length - 1) ...[
                      ResizableContainerDivider(
                        config: widget.children[i].divider,
                        direction: widget.direction,
                        onResizeUpdate: (delta) => manager.adjustChildSize(
                          index: i,
                          delta: delta,
                        ),
                      ),
                    ],
                  ],
                ],
              );
            }
          },
        );
      },
    );
  }

  double _getAvailableSpace(BoxConstraints constraints) {
    final totalSpace = constraints.maxForDirection(widget.direction);
    final dividerSpace = widget.children
        .take(widget.children.length - 1)
        .map((child) => child.divider)
        .map((divider) => divider.thickness + divider.padding)
        .sum();

    return totalSpace - dividerSpace;
  }

  double _getChildSize({
    required int index,
    required Axis direction,
    required BoxConstraints constraints,
  }) {
    if (direction != direction) {
      return constraints.maxForDirection(direction);
    } else {
      return controller.pixels[index];
    }
  }
}

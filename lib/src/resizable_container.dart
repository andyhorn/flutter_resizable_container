import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/extensions/box_constraints_ext.dart';
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
    ResizableDivider? divider,
  }) : divider = divider ?? const ResizableDivider();

  /// A list of resizable [ResizableChild] containing the child [Widget]s and
  /// their sizing configuration.
  final List<ResizableChild> children;

  /// The controller that will be used to manage programmatic resizing of the children.
  final ResizableController? controller;

  /// The direction along which the child widgets will be laid and resized.
  final Axis direction;

  /// Configuration values for the dividing space/line between this container's [children].
  final ResizableDivider divider;

  @override
  State<ResizableContainer> createState() => _ResizableContainerState();
}

class _ResizableContainerState extends State<ResizableContainer> {
  late final controller = widget.controller ?? ResizableController();
  late final isDefaultController = widget.controller == null;
  late final manager = ResizableControllerManager(controller);
  late final keys = List.generate(
    widget.children.length,
    (_) => GlobalKey(),
  );

  var initialized = false;
  var initScheduled = false;

  @override
  void initState() {
    super.initState();

    manager.setChildren(widget.children);
  }

  @override
  void didUpdateWidget(covariant ResizableContainer oldWidget) {
    final hasChanges = !listEquals(oldWidget.children, widget.children);

    if (hasChanges) {
      manager.updateChildren(widget.children);
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
            final hasFlexOrShrink = widget.children.any(
              (child) => child.size.isShrink || child.size.isExpand,
            );

            return Flex(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              direction: widget.direction,
              children: [
                for (var i = 0; i < widget.children.length; i++) ...[
                  Builder(
                    builder: (context) {
                      final child = widget.children[i].child;
                      final size = widget.children[i].size;
                      final key = keys[i];

                      final scheduleInit = hasFlexOrShrink && !initScheduled;
                      final shrink = !initialized && size.isShrink;
                      final expand = !initialized && size.isExpand;

                      if (scheduleInit) {
                        Timer.run(_sizeInit);
                        initScheduled = true;
                      }

                      if (shrink) {
                        // Use UnconstrainedBox to allow the child to shrink
                        // to its minimum size.
                        return UnconstrainedBox(
                          key: key,
                          child: child,
                        );
                      }

                      if (expand) {
                        // Use Expanded to allow the child to expand to fill
                        // the available space, mediated by its "flex" value.
                        return Expanded(
                          key: key,
                          flex: size.value.toInt(),
                          child: child,
                        );
                      }

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
                        key: key,
                        height: height,
                        width: width,
                        child: child,
                      );
                    },
                  ),
                  if (i < widget.children.length - 1) ...[
                    ResizableContainerDivider(
                      config: widget.divider,
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
          },
        );
      },
    );
  }

  double _getAvailableSpace(BoxConstraints constraints) {
    final totalSpace = constraints.maxForDirection(widget.direction);
    final numDividers = widget.children.length - 1;
    final dividerSpace = numDividers * widget.divider.thickness +
        numDividers * widget.divider.padding;
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

  void _sizeInit() {
    final sizes = keys.map<double>((key) {
      final size = _getRenderBoxSize(key);

      if (size == null) {
        return 0;
      }

      return switch (widget.direction) {
        Axis.horizontal => size.width,
        Axis.vertical => size.height,
      };
    });

    manager.setSizes(sizes.toList());
    initialized = true;
  }

  Size? _getRenderBoxSize(GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size;
  }
}

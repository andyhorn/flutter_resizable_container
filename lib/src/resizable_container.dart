import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/extensions/box_constraints_ext.dart';
import 'package:flutter_resizable_container/src/extensions/iterable_ext.dart';
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
  late var keys = _generateKeys();

  List<GlobalKey> _generateKeys() => List.generate(
        widget.children.length,
        (_) => GlobalKey(),
      );

  @override
  void initState() {
    super.initState();

    controller.setChildren(widget.children);
  }

  @override
  void didUpdateWidget(covariant ResizableContainer oldWidget) {
    final didChildrenChange = !listEquals(oldWidget.children, widget.children);
    final didDirectionChange = widget.direction != oldWidget.direction;
    final hasChanges = didChildrenChange || didDirectionChange;

    if (didChildrenChange) {
      controller.setChildren(widget.children);
    }

    if (hasChanges) {
      keys = _generateKeys();
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
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _readSizesAfterLayout();
              });

              return PreLayout(
                availableSpace: availableSpace,
                children: widget.children,
                direction: widget.direction,
                divider: widget.divider,
                keys: keys,
                sizes: controller.sizes,
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
            }
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
    if (direction != direction) {
      return constraints.maxForDirection(direction);
    } else {
      return controller.pixels[index];
    }
  }

  void _readSizesAfterLayout() {
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

    manager.setRenderedSizes(sizes.toList());
  }

  Size? _getRenderBoxSize(GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size;
  }
}

class PreLayout extends StatelessWidget {
  const PreLayout({
    super.key,
    required this.availableSpace,
    required this.children,
    required this.direction,
    required this.divider,
    required this.keys,
    required this.sizes,
  });

  final double availableSpace;
  final List<ResizableChild> children;
  final Axis direction;
  final ResizableDivider divider;
  final List<GlobalKey> keys;
  final List<ResizableSize> sizes;

  @override
  Widget build(BuildContext context) {
    final totalPixels =
        sizes.where((size) => size.isPixels).sum((size) => size.value);

    return Flex(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      direction: direction,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Builder(builder: (context) {
            final size = sizes[i];
            final value = size.value;

            if (size.isPixels) {
              final constrained = _getConstrainedSize(
                value: value,
                minimum: children[i].minSize,
                maximum: children[i].maxSize,
              );

              return SizedBox(
                key: keys[i],
                height: direction == Axis.horizontal ? null : constrained,
                width: direction == Axis.horizontal ? constrained : null,
                child: children[i].child,
              );
            }

            if (size.isRatio) {
              final size = (availableSpace - totalPixels) * value;
              final constrained = _getConstrainedSize(
                value: size,
                minimum: children[i].minSize,
                maximum: children[i].maxSize,
              );

              return SizedBox(
                key: keys[i],
                height: direction == Axis.horizontal ? null : constrained,
                width: direction == Axis.horizontal ? constrained : null,
                child: children[i].child,
              );
            }

            if (size.isShrink) {
              return UnconstrainedBox(
                key: keys[i],
                child: children[i].child,
              );
            }

            return Expanded(
              key: keys[i],
              flex: value.toInt(),
              child: children[i].child,
            );
          }),
          if (i < children.length - 1) ...[
            ResizableContainerDivider(
              config: divider,
              direction: direction,
              onResizeUpdate: (_) {},
            ),
          ],
        ],
      ],
    );
  }

  double _getConstrainedSize({
    required double value,
    required double? minimum,
    required double? maximum,
  }) {
    if (minimum == null && maximum == null) {
      return value;
    }

    var adjustedSize = min(value, maximum ?? double.infinity);
    adjustedSize = max(adjustedSize, 0);

    return adjustedSize;
  }
}

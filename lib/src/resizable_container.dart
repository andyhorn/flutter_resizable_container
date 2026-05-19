import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/extensions/box_constraints_ext.dart';
import 'package:flutter_resizable_container/src/extensions/iterable_ext.dart';
import 'package:flutter_resizable_container/src/extensions/num_ext.dart';
import 'package:flutter_resizable_container/src/hide_animation_coordinator.dart';
import 'package:flutter_resizable_container/src/layout/resizable_layout.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_resizable_container/src/resizable_controller.dart';
import 'package:flutter_resizable_container/src/resizable_size.dart';

/// A container that holds multiple child [Widget]s that can be resized.
///
/// Dividing lines will be added between each child. Dragging the dividers
/// will resize the children along the [direction] axis.
class ResizableContainer extends StatefulWidget {
  /// Creates a new [ResizableContainer] with the given [direction] and list
  /// of [children] Widgets.
  const ResizableContainer({
    super.key,
    required this.children,
    required this.direction,
    this.controller,
    this.cascadeNegativeDelta = false,
    this.hideAnimation,
  });

  /// A list of [ResizableChild] containing the child [Widget]s and
  /// their sizing configuration.
  final List<ResizableChild> children;

  /// The controller that will be used to manage programmatic resizing of the children.
  final ResizableController? controller;

  /// The direction along which the child widgets will be laid and resized.
  final Axis direction;

  /// When enabled, reducing the size of a child beyond its lower bound will reduce the
  /// size of its sibling(s). Defaults to `false`.
  final bool cascadeNegativeDelta;

  /// Optional configuration for animating hide/show transitions triggered by
  /// [ResizableController.hide] and [ResizableController.show].
  ///
  /// When `null` (the default), hidden children collapse and restored
  /// children expand in a single frame. When non-null, the affected child and
  /// its siblings tween between their current rendered sizes and the new
  /// target sizes over [ResizableHideAnimation.duration] using
  /// [ResizableHideAnimation.curve]. Other size transitions (divider drag,
  /// [ResizableController.setSizes], available-space changes) remain instant.
  final ResizableHideAnimation? hideAnimation;

  @override
  State<ResizableContainer> createState() => _ResizableContainerState();
}

class _ResizableContainerState extends State<ResizableContainer>
    with TickerProviderStateMixin {
  late final controller = widget.controller ?? ResizableController();
  late final isDefaultController = widget.controller == null;
  late final manager = ResizableControllerManager(controller);

  late final _animation = HideAnimationCoordinator(
    vsync: this,
    onChanged: _rebuild,
  );

  Set<int> _prevHiddenIndices = const <int>{};
  double? _lastAvailableSpace;

  @override
  void initState() {
    super.initState();

    manager.initChildren(widget.children);
    manager.setCascadeNegativeDelta(widget.cascadeNegativeDelta);
    _prevHiddenIndices = Set.of(controller.hiddenIndices);
    controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant ResizableContainer oldWidget) {
    final childrenChanged = !listEquals(oldWidget.children, widget.children);
    final directionChanged = oldWidget.direction != widget.direction;
    final cascadeChanged =
        oldWidget.cascadeNegativeDelta != widget.cascadeNegativeDelta;

    if (childrenChanged) {
      _animation.cancel();
      controller.setChildren(widget.children);
      _prevHiddenIndices = Set.of(controller.hiddenIndices);
    }

    if (cascadeChanged) {
      manager.setCascadeNegativeDelta(widget.cascadeNegativeDelta);
    }

    if (childrenChanged || directionChanged) {
      manager.setNeedsLayout();
    }

    if (oldWidget.hideAnimation != widget.hideAnimation &&
        widget.hideAnimation == null) {
      _animation.reset();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    _animation.dispose();
    if (isDefaultController) {
      controller.dispose();
    }

    super.dispose();
  }

  void _rebuild() {
    if (!mounted) return;
    setState(() {});
  }

  void _onControllerChanged() {
    if (!mounted) return;

    final newHidden = controller.hiddenIndices;
    if (setEquals(newHidden, _prevHiddenIndices)) {
      return;
    }

    if (widget.hideAnimation != null) {
      // The controller has already flipped its hidden state, but pixels and
      // dividers are still rendered at the pre-transition values, so the
      // from-snapshot must be derived against the previous hidden set.
      _animation.beginCapture(
        _deriveFullSizesFromController(hiddenIndices: _prevHiddenIndices),
      );
    }

    _prevHiddenIndices = Set.of(newHidden);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableSpace = _getAvailableSpace(constraints);

        if (_animation.phase != HideAnimationPhase.idle &&
            _lastAvailableSpace != null &&
            availableSpace != _lastAvailableSpace) {
          _animation.cancel();
        }
        _lastAvailableSpace = availableSpace;

        manager.setAvailableSpace(availableSpace);

        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) => _buildForPhase(constraints),
        );
      },
    );
  }

  Widget _buildForPhase(BoxConstraints constraints) {
    switch (_animation.phase) {
      case HideAnimationPhase.animating:
        return _flexFromFullSizes(
          constraints: constraints,
          sizes: _animation.currentSizes!,
        );

      case HideAnimationPhase.capturing:
        return Stack(
          fit: StackFit.expand,
          children: [
            _buildOffstageMeasureLayout(),
            _flexFromFullSizes(
              constraints: constraints,
              sizes: _animation.currentSizes!,
            ),
          ],
        );

      case HideAnimationPhase.idle:
        if (controller.needsLayout) {
          return _buildLayout(_scheduleSetRenderedSizes);
        }
        return _flexFromFullSizes(
          constraints: constraints,
          sizes: _deriveFullSizesFromController(),
        );
    }
  }

  Widget _buildLayout(ValueChanged<List<double>> onComplete) {
    return ResizableLayout(
      direction: widget.direction,
      onComplete: onComplete,
      sizes: controller.sizes,
      resizableChildren: widget.children,
      hiddenIndices: controller.hiddenIndices,
      children: _buildLayoutChildren((i) => widget.children[i].child),
    );
  }

  Widget _buildOffstageMeasureLayout() {
    // Run the layout offstage with placeholder children so the real widgets
    // aren't inflated twice. Any [ResizableSizeShrink] entry is replaced with
    // a fixed-pixel size based on the controller's last-rendered value — the
    // shrink dry-layout produced that value already, so it is the size the
    // offstage pass would otherwise measure.
    final overrideSizes = <ResizableSize>[
      for (var i = 0; i < controller.sizes.length; i++)
        controller.sizes[i] is ResizableSizeShrink
            ? ResizableSize.pixels(controller.pixels[i])
            : controller.sizes[i],
    ];

    return Offstage(
      offstage: true,
      child: ResizableLayout(
        direction: widget.direction,
        onComplete: _captureTarget,
        sizes: overrideSizes,
        resizableChildren: widget.children,
        hiddenIndices: controller.hiddenIndices,
        children: _buildLayoutChildren((_) => const SizedBox.shrink()),
      ),
    );
  }

  /// Builds the alternating child/divider list that [ResizableLayout]
  /// expects. [childBuilder] supplies the widget rendered for each child
  /// slot — the real child for the live layout, a placeholder for the
  /// offstage measurement.
  List<Widget> _buildLayoutChildren(Widget Function(int index) childBuilder) {
    return [
      for (var i = 0; i < widget.children.length; i++) ...[
        childBuilder(i),
        if (i < widget.children.length - 1)
          ResizableContainerDivider.placeholder(
            config: widget.children[i].divider,
            direction: widget.direction,
          ),
      ],
    ];
  }

  void _scheduleSetRenderedSizes(List<double> sizes) {
    final childSizes = sizes.evenIndices().toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      manager.setRenderedSizes(childSizes);
    });
  }

  void _captureTarget(List<double> sizes) {
    final fullTarget = List.of(sizes);
    final childSizes = sizes.evenIndices().toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      manager.setRenderedSizes(childSizes);

      // If hideAnimation was cleared between the capture-target frame and
      // this callback, fall back to the instant-snap path.
      final animation = widget.hideAnimation;
      if (animation == null) {
        _animation.cancel();
        return;
      }

      _animation.startAnimation(target: fullTarget, animation: animation);
    });
  }

  List<double> _deriveFullSizesFromController({Set<int>? hiddenIndices}) {
    final hidden = hiddenIndices ?? controller.hiddenIndices;
    final result = <double>[];
    for (var i = 0; i < widget.children.length; i++) {
      result.add(controller.pixels[i]);
      if (i < widget.children.length - 1) {
        final dividerHidden = hidden.contains(i) || hidden.contains(i + 1);
        final config = widget.children[i].divider;
        result.add(dividerHidden ? 0.0 : config.thickness + config.padding);
      }
    }
    return result;
  }

  Widget _flexFromFullSizes({
    required BoxConstraints constraints,
    required List<double> sizes,
  }) {
    return Flex(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      direction: widget.direction,
      children: [
        for (var i = 0; i < widget.children.length; i++) ...[
          Builder(
            key: widget.children[i].key,
            builder: (context) {
              final mainSize = sizes[i * 2];
              return SizedBox(
                width: widget.direction == Axis.horizontal
                    ? mainSize
                    : constraints.maxForDirection(Axis.horizontal),
                height: widget.direction == Axis.vertical
                    ? mainSize
                    : constraints.maxForDirection(Axis.vertical),
                child: widget.children[i].child,
              );
            },
          ),
          if (i < widget.children.length - 1)
            _buildDividerSlot(
              dividerIndex: i,
              size: sizes[i * 2 + 1],
              constraints: constraints,
            ),
        ],
      ],
    );
  }

  Widget _buildDividerSlot({
    required int dividerIndex,
    required double size,
    required BoxConstraints constraints,
  }) {
    if (size == 0) {
      return const SizedBox.shrink();
    }
    final divider = ResizableContainerDivider(
      config: widget.children[dividerIndex].divider,
      direction: widget.direction,
      onResizeUpdate: (delta) => manager.adjustChildSize(
        index: dividerIndex,
        delta: delta,
      ),
    );
    return SizedBox(
      width: widget.direction == Axis.horizontal
          ? size
          : constraints.maxForDirection(Axis.horizontal),
      height: widget.direction == Axis.vertical
          ? size
          : constraints.maxForDirection(Axis.vertical),
      child: divider,
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
}

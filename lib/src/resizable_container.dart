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
    this.resizable = true,
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

  /// Whether dividers in this container respond to user input.
  ///
  /// When `false`, every divider is locked — drag, tap, and hover callbacks
  /// will not fire and the resize cursor is not shown. Individual dividers
  /// can also be locked via [ResizableDivider.enabled]; a divider is
  /// interactive only when both this flag and its own `enabled` flag are
  /// `true`. Programmatic resizing via [ResizableController] is unaffected.
  ///
  /// Defaults to `true`.
  final bool resizable;

  @override
  State<ResizableContainer> createState() => _ResizableContainerState();
}

class _ResizableContainerState extends State<ResizableContainer>
    with TickerProviderStateMixin {
  late ResizableController controller;
  late bool isDefaultController;
  late ResizableControllerManager manager;

  late final _animation = HideAnimationCoordinator(
    vsync: this,
    onChanged: _rebuild,
  );

  Set<int> _prevHiddenIndices = const <int>{};
  double? _lastAvailableSpace;

  @override
  void initState() {
    super.initState();

    isDefaultController = widget.controller == null;
    controller = widget.controller ?? ResizableController();
    manager = ResizableControllerManager(controller);

    manager.initChildren(widget.children);
    manager.setCascadeNegativeDelta(widget.cascadeNegativeDelta);
    _prevHiddenIndices = Set.of(controller.hiddenIndices);
    controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant ResizableContainer oldWidget) {
    final controllerChanged = oldWidget.controller != widget.controller;
    final structuralChange =
        _isStructuralChange(oldWidget.children, widget.children);
    final configChange =
        !structuralChange && !listEquals(oldWidget.children, widget.children);
    final directionChanged = oldWidget.direction != widget.direction;
    final cascadeChanged =
        oldWidget.cascadeNegativeDelta != widget.cascadeNegativeDelta;

    if (controllerChanged) {
      _animation.cancel();
      controller.removeListener(_onControllerChanged);
      if (isDefaultController) {
        controller.dispose();
      }

      controller = widget.controller ?? ResizableController();
      isDefaultController = widget.controller == null;
      manager = ResizableControllerManager(controller);

      manager.initChildren(widget.children);
      manager.setCascadeNegativeDelta(widget.cascadeNegativeDelta);
      _prevHiddenIndices = Set.of(controller.hiddenIndices);
      _lastAvailableSpace = null;
      controller.addListener(_onControllerChanged);
    } else if (structuralChange) {
      _animation.cancel();
      controller.setChildren(widget.children);
      _prevHiddenIndices = Set.of(controller.hiddenIndices);
    } else if (configChange) {
      manager.updateChildrenInPlace(widget.children);
    }

    if (!controllerChanged && cascadeChanged) {
      manager.setCascadeNegativeDelta(widget.cascadeNegativeDelta);
    }

    if (!controllerChanged && (structuralChange || directionChanged)) {
      manager.setNeedsLayout();
    }

    if (oldWidget.hideAnimation != widget.hideAnimation &&
        widget.hideAnimation == null) {
      _animation.reset();
    }

    super.didUpdateWidget(oldWidget);
  }

  /// Whether [oldChildren] and [newChildren] differ in ways that invalidate
  /// the controller's layout state — the number of children or any of their
  /// declared sizes. Differences confined to divider config or child widget
  /// instances are not structural.
  bool _isStructuralChange(
    List<ResizableChild> oldChildren,
    List<ResizableChild> newChildren,
  ) {
    if (oldChildren.length != newChildren.length) {
      return true;
    }
    for (var i = 0; i < oldChildren.length; i++) {
      if (oldChildren[i].size != newChildren[i].size) {
        return true;
      }
    }
    return false;
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

        return ListenableBuilder(
          // Listen to both the controller (structural changes) and the
          // needsLayout flag so the build path swaps between the cold and
          // live paths without depending on the main listener firing after
          // every layout.
          listenable: Listenable.merge([
            controller,
            controller.needsLayoutListenable,
          ]),
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
        // The cold (size-resolution) path runs whenever the controller's
        // sizes need re-resolving; otherwise feed live pixels into the
        // render object so drag updates relayout without rebuilding.
        return _buildLayout(
          onComplete: _scheduleSetRenderedSizes,
          livePixels:
              controller.needsLayout ? null : controller.pixelsListenable,
        );
    }
  }

  Widget _buildLayout({
    required ValueChanged<List<double>> onComplete,
    required ValueListenable<List<double>>? livePixels,
  }) {
    return ResizableLayout(
      direction: widget.direction,
      onComplete: onComplete,
      sizes: controller.sizes,
      resizableChildren: widget.children,
      hiddenIndices: controller.hiddenIndices,
      livePixels: livePixels,
      children: _buildLayoutChildren(
        childBuilder: (i) => widget.children[i].child,
        dividerBuilder: _buildInteractiveDivider,
      ),
    );
  }

  Widget _buildInteractiveDivider(int dividerIndex) {
    if (_isDividerHidden(dividerIndex, controller.hiddenIndices)) {
      return const SizedBox.shrink();
    }
    return ResizableContainerDivider(
      config: widget.children[dividerIndex].divider,
      direction: widget.direction,
      onResizeUpdate: (delta) => manager.adjustChildSize(
        index: dividerIndex,
        delta: delta,
      ),
    );
  }

  /// Whether the divider at [dividerIndex] is hidden — true when either
  /// adjacent child is in [hiddenIndices].
  static bool _isDividerHidden(int dividerIndex, Set<int> hiddenIndices) {
    return hiddenIndices.contains(dividerIndex) ||
        hiddenIndices.contains(dividerIndex + 1);
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
        children: _buildLayoutChildren(
          childBuilder: (_) => const SizedBox.shrink(),
          dividerBuilder: (i) => ResizableContainerDivider.placeholder(
            config: widget.children[i].divider,
            direction: widget.direction,
          ),
        ),
      ),
    );
  }

  /// Builds the alternating child/divider list that [ResizableLayout]
  /// expects. [childBuilder] supplies the widget rendered for each child
  /// slot; [dividerBuilder] supplies the widget rendered for each divider
  /// slot (interactive divider for the live layout, placeholder for the
  /// offstage measurement). Children are wrapped in [RepaintBoundary] so a
  /// single child's paint dirtiness doesn't propagate to siblings during a
  /// drag.
  List<Widget> _buildLayoutChildren({
    required Widget Function(int index) childBuilder,
    required Widget Function(int dividerIndex) dividerBuilder,
  }) {
    return [
      for (var i = 0; i < widget.children.length; i++) ...[
        RepaintBoundary(child: childBuilder(i)),
        if (i < widget.children.length - 1) dividerBuilder(i),
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

  List<double> _deriveFullSizesFromController({
    required Set<int> hiddenIndices,
  }) {
    final result = <double>[];
    for (var i = 0; i < widget.children.length; i++) {
      result.add(controller.pixels[i]);
      if (i < widget.children.length - 1) {
        final config = widget.children[i].divider;
        result.add(
          _isDividerHidden(i, hiddenIndices)
              ? 0.0
              : config.thickness + config.padding,
        );
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
                child: RepaintBoundary(child: widget.children[i].child),
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
    final config = widget.children[dividerIndex].divider;
    final divider = ResizableContainerDivider(
      config: config,
      direction: widget.direction,
      enabled: widget.resizable && config.enabled,
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/extensions/box_constraints_ext.dart';
import 'package:flutter_resizable_container/src/extensions/iterable_ext.dart';
import 'package:flutter_resizable_container/src/extensions/num_ext.dart';
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
    with SingleTickerProviderStateMixin {
  late final controller = widget.controller ?? ResizableController();
  late final isDefaultController = widget.controller == null;
  late final manager = ResizableControllerManager(controller);

  AnimationController? _animController;

  /// Full alternating list of [child0, divider0, child1, divider1, …, childN]
  /// pixel sizes captured at the start of an animation.
  List<double>? _fromSizes;

  /// Full alternating list of pixel sizes the animation tweens toward.
  List<double>? _toSizes;

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
      _cancelAnimation();
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
      _disposeAnimationController();
      _fromSizes = null;
      _toSizes = null;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    _disposeAnimationController();
    if (isDefaultController) {
      controller.dispose();
    }

    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;

    final newHidden = controller.hiddenIndices;
    if (setEquals(newHidden, _prevHiddenIndices)) {
      return;
    }

    if (widget.hideAnimation != null) {
      // Snapshot the currently-displayed sizes — using the PREVIOUS hidden
      // set for divider visibility, since the controller has already flipped
      // its hidden state but pixels and dividers are still rendered at the
      // pre-transition values.
      final from = _isAnimating
          ? _interpolatedSizes()
          : _deriveFullSizesFromController(hiddenIndices: _prevHiddenIndices);
      _animController?.stop();
      _fromSizes = from;
      _toSizes = null;
    }

    _prevHiddenIndices = Set.of(newHidden);
  }

  /// Snapshot of the current animation tween at this moment.
  List<double> _interpolatedSizes() {
    return _lerpFullSizes(
      from: _fromSizes!,
      to: _toSizes!,
      t: widget.hideAnimation!.curve.transform(_animController!.value),
    );
  }

  List<double> _lerpFullSizes({
    required List<double> from,
    required List<double> to,
    required double t,
  }) {
    return [
      for (var i = 0; i < from.length; i++) from[i] + (to[i] - from[i]) * t,
    ];
  }

  bool get _isAnimating {
    final anim = _animController;
    return anim != null &&
        anim.isAnimating &&
        _fromSizes != null &&
        _toSizes != null;
  }

  bool get _isCapturingTarget => _fromSizes != null && _toSizes == null;

  void _ensureAnimationController() {
    _animController ??= AnimationController(vsync: this)
      ..addListener(_onAnimationTick)
      ..addStatusListener(_onAnimationStatus);
  }

  void _disposeAnimationController() {
    final anim = _animController;
    if (anim == null) return;
    anim
      ..stop()
      ..dispose();
    _animController = null;
  }

  /// Drives a rebuild on every animation tick. AnimatedBuilder below listens
  /// only to [controller] (whose listener is registered before this widget's
  /// first build), so a separate hook is needed to pick up animation ticks
  /// without the per-rebuild churn of `Listenable.merge`.
  void _onAnimationTick() {
    if (!mounted) return;
    setState(() {});
  }

  void _onAnimationStatus(AnimationStatus status) {
    // Only react to natural completion. We never call `reverse()`, so a
    // `dismissed` status only ever appears as a transient side-effect of
    // `forward(from: 0.0)` resetting the controller's value before the new
    // tween begins — and clearing the tween state at that point would
    // suppress the new animation entirely.
    if (status != AnimationStatus.completed) return;
    if (!mounted) return;
    setState(() {
      _fromSizes = null;
      _toSizes = null;
    });
  }

  void _cancelAnimation() {
    _animController?.stop();
    _fromSizes = null;
    _toSizes = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableSpace = _getAvailableSpace(constraints);

        if ((_isAnimating || _isCapturingTarget) &&
            _lastAvailableSpace != null &&
            availableSpace != _lastAvailableSpace) {
          _cancelAnimation();
        }
        _lastAvailableSpace = availableSpace;

        manager.setAvailableSpace(availableSpace);

        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (_isAnimating) {
              return _buildAnimatedFlex(constraints);
            }

            if (_isCapturingTarget) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  _buildOffstageMeasureLayout(),
                  _buildFromSizesFlex(constraints),
                ],
              );
            }

            if (controller.needsLayout) {
              return _buildLayout(_scheduleSetRenderedSizes);
            }

            return _buildFlex(constraints);
          },
        );
      },
    );
  }

  Widget _buildLayout(ValueChanged<List<double>> onComplete) {
    return ResizableLayout(
      direction: widget.direction,
      onComplete: onComplete,
      sizes: controller.sizes,
      resizableChildren: widget.children,
      hiddenIndices: controller.hiddenIndices,
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
        children: [
          for (var i = 0; i < widget.children.length; i++) ...[
            const SizedBox.shrink(),
            if (i < widget.children.length - 1) ...[
              ResizableContainerDivider.placeholder(
                config: widget.children[i].divider,
                direction: widget.direction,
              ),
            ],
          ],
        ],
      ),
    );
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

      // If hideAnimation was cleared between the capture-target frame and
      // this callback, fall back to the instant-snap path.
      final animation = widget.hideAnimation;
      if (animation == null) {
        _fromSizes = null;
        _toSizes = null;
        manager.setRenderedSizes(childSizes);
        return;
      }

      manager.setRenderedSizes(childSizes);
      _toSizes = fullTarget;
      _ensureAnimationController();
      _animController!
        ..duration = animation.duration
        ..forward(from: 0.0);
    });
  }

  Widget _buildAnimatedFlex(BoxConstraints constraints) {
    return _flexFromFullSizes(
      constraints: constraints,
      sizes: _interpolatedSizes(),
    );
  }

  Widget _buildFromSizesFlex(BoxConstraints constraints) {
    return _flexFromFullSizes(
      constraints: constraints,
      sizes: _fromSizes!,
    );
  }

  Widget _buildFlex(BoxConstraints constraints) {
    return _flexFromFullSizes(
      constraints: constraints,
      sizes: _deriveFullSizesFromController(),
    );
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
              final child = widget.children[i].child;
              final mainSize = sizes[i * 2];
              return SizedBox(
                width: widget.direction == Axis.horizontal
                    ? mainSize
                    : constraints.maxForDirection(Axis.horizontal),
                height: widget.direction == Axis.vertical
                    ? mainSize
                    : constraints.maxForDirection(Axis.vertical),
                child: child,
              );
            },
          ),
          if (i < widget.children.length - 1) ...[
            _buildDividerSlot(
              dividerIndex: i,
              size: sizes[i * 2 + 1],
              constraints: constraints,
            ),
          ],
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

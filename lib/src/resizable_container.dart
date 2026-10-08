import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/extensions/box_constraints_ext.dart';
import 'package:flutter_resizable_container/src/extensions/iterable_ext.dart';
import 'package:flutter_resizable_container/src/extensions/resizable_children_ext.dart';
import 'package:flutter_resizable_container/src/hidden_child_scope.dart';
import 'package:flutter_resizable_container/src/hide_animation_coordinator.dart';
import 'package:flutter_resizable_container/src/layout/resizable_allocation.dart';
import 'package:flutter_resizable_container/src/layout/resizable_layout.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_resizable_container/src/resizable_controller.dart';

/// A container that holds multiple child [Widget]s that can be resized.
///
/// Dividing lines will be added between each child. Dragging the dividers
/// will resize the children along the [direction] axis.
///
/// The container divides the space its parent gives it, so it needs a bounded
/// width and height. Wrap it in an [Expanded] or a [SizedBox] when placing it
/// inside a [Row], [Column], or scrollable.
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
    onChanged: _onAnimationChanged,
  );

  Set<int> _prevHiddenIndices = const <int>{};
  bool _remeasureShrinkOnIdle = false;
  double? _lastContainerExtent;

  /// Pre-hide widths of `shrink` children being shown, for the animation
  /// target because their last rendered width is 0 while hidden.
  final Map<int, double> _revealedShrinkPixels = <int, double>{};

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
      _lastContainerExtent = null;
      controller.addListener(_onControllerChanged);
    } else if (structuralChange) {
      _animation.cancel();
      // `manager.setChildren` clears the hidden set and notifies synchronously,
      // so the listener must already expect the empty set.
      _prevHiddenIndices = const <int>{};
      manager.setChildren(widget.children);
    } else if (configChange) {
      manager.updateChildrenInPlace(widget.children);
    }

    if (directionChanged) {
      _animation.cancel();
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
  /// the controller's layout state — the number of children, any of their
  /// declared sizes, or their keys. Differences confined to divider config or
  /// child widget instances are not structural.
  bool _isStructuralChange(
    List<ResizableChild> oldChildren,
    List<ResizableChild> newChildren,
  ) {
    if (oldChildren.length != newChildren.length) {
      return true;
    }
    for (var i = 0; i < oldChildren.length; i++) {
      if (oldChildren[i].size != newChildren[i].size ||
          oldChildren[i].key != newChildren[i].key) {
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

  void _onAnimationChanged() {
    if (_remeasureShrinkOnIdle && _animation.phase == HideAnimationPhase.idle) {
      // The animation targeted a width saved before the child was hidden, which
      // is stale if its content changed in the meantime.
      _remeasureShrinkOnIdle = false;
      manager.setNeedsLayout();
    }
    _rebuild();
  }

  void _onControllerChanged() {
    if (!mounted) return;

    final newHidden = controller.hiddenIndices;
    if (setEquals(newHidden, _prevHiddenIndices)) {
      return;
    }

    if (widget.hideAnimation != null) {
      _beginHideAnimation(revealed: _prevHiddenIndices.difference(newHidden));
    }

    _prevHiddenIndices = Set.of(newHidden);

    // Hiding or showing a child changes the visible divider space, which is
    // only recomputed when the LayoutBuilder re-runs.
    _rebuild();
  }

  void _beginHideAnimation({required Set<int> revealed}) {
    // An unfinished capture still needs the entries recorded for it.
    if (_animation.phase != HideAnimationPhase.capturing) {
      _revealedShrinkPixels.clear();
    }

    for (final index in revealed) {
      // A structural change resets the controller, so a hidden index can
      // point past the end of the new list.
      if (index >= controller.sizes.length ||
          controller.sizes[index] is! ResizableSizeShrink) {
        continue;
      }

      final pixels = manager.savedPixels(index);
      if (pixels == null) {
        // Without a known width the animation target can't be computed, so
        // let the real layout measure it and show the child instantly.
        _animation.cancel();
        return;
      }

      _revealedShrinkPixels[index] = pixels;
    }

    // The controller has already flipped its hidden state, but pixels and
    // dividers are still rendered at the pre-transition values, so the
    // from-snapshot must be derived against the previous hidden set.
    _animation.beginCapture(
      _deriveFullSizesFromController(hiddenIndices: _prevHiddenIndices),
    );
    if (_animation.claimTargetSlot()) {
      final capturingManager = manager;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _startAnimationFromCapture(capturingManager),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _checkBounded(constraints);

        final availableSpace = _getAvailableSpace(constraints);
        final containerExtent = constraints.maxForDirection(widget.direction);

        if (_animation.phase != HideAnimationPhase.idle &&
            _lastContainerExtent != null &&
            containerExtent != _lastContainerExtent) {
          _animation.cancel();
        }
        _lastContainerExtent = containerExtent;

        manager.setAvailableSpace(availableSpace);

        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return _ContainerLayout(
              direction: widget.direction,
              resizable: widget.resizable,
              resizableChildren: widget.children,
              sizes: controller.sizes,
              hiddenIndices: controller.hiddenIndices,
              fixedSizes: _fixedSizesForPhase(),
              collapsing: _animation.phase != HideAnimationPhase.idle,
              onComplete: _scheduleSetRenderedSizes,
              onResizeUpdate: (index, delta) => manager.adjustChildSize(
                index: index,
                delta: delta,
              ),
            );
          },
        );
      },
    );
  }

  void _checkBounded(BoxConstraints constraints) {
    final unboundedAxes = [
      if (!constraints.hasBoundedWidth) 'width',
      if (!constraints.hasBoundedHeight) 'height',
    ];
    if (unboundedAxes.isEmpty) return;

    throw FlutterError.fromParts([
      ErrorSummary(
        'ResizableContainer was given unbounded '
        '${unboundedAxes.join(' and ')}.',
      ),
      ErrorDescription(
        'A ResizableContainer divides the space its parent gives it, so it '
        'needs a bounded width and height. It was laid out with constraints '
        '$constraints.',
      ),
      ErrorHint(
        'This usually happens when a ResizableContainer is placed inside a '
        'Row, Column, ListView, or other widget that gives its children '
        'unlimited space along one axis. Wrap the ResizableContainer in an '
        'Expanded, Flexible, SizedBox, or ConstrainedBox, or give its '
        'parent a bounded size.',
      ),
    ]);
  }

  /// The full child/divider sizes to lay out at, or `null` to have
  /// [ResizableLayout] resolve and report them.
  List<double>? _fixedSizesForPhase() {
    switch (_animation.phase) {
      case HideAnimationPhase.animating:
      case HideAnimationPhase.capturing:
        return _animation.currentSizes;

      case HideAnimationPhase.idle:
        if (controller.needsLayout) {
          return null;
        }
        return _deriveFullSizesFromController();
    }
  }

  void _scheduleSetRenderedSizes(List<double> sizes) {
    final scheduledManager = manager;
    final childSizes = sizes.evenIndices().toList();
    final scheduledInvalidations = scheduledManager.invalidations;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || scheduledManager != manager) return;
      if (_animation.phase != HideAnimationPhase.idle) return;
      if (scheduledManager.invalidations != scheduledInvalidations) return;
      scheduledManager.setRenderedSizes(childSizes);
    });
  }

  void _startAnimationFromCapture(ResizableControllerManager capturingManager) {
    if (!mounted || capturingManager != manager) return;
    if (_animation.phase != HideAnimationPhase.capturing) return;

    final pixels = controller.pixels;
    final fullTarget = allocateSizes(
      extent: _lastContainerExtent ?? 0,
      sizes: controller.sizes,
      dividers: widget.children.dividers,
      hiddenIndices: controller.hiddenIndices,
      measureShrink: (index, cap) => math.min(
        _revealedShrinkPixels[index] ?? pixels[index],
        cap,
      ),
    );
    _remeasureShrinkOnIdle = _revealedShrinkPixels.isNotEmpty;
    _revealedShrinkPixels.clear();

    manager.setRenderedSizes(fullTarget.evenIndices().toList());

    // didUpdateWidget resets the coordinator when hideAnimation is cleared, so
    // the capturing phase guarantees it is non-null here.
    _animation.startAnimation(
      target: fullTarget,
      animation: widget.hideAnimation!,
    );
  }

  List<double> _deriveFullSizesFromController({Set<int>? hiddenIndices}) {
    final hidden = hiddenIndices ?? controller.hiddenIndices;
    final pixels = controller.pixels;
    final dividerSizes = dividerExtents(widget.children.dividers, hidden);
    final result = <double>[];
    for (var i = 0; i < widget.children.length; i++) {
      result.add(pixels[i]);
      if (i < dividerSizes.length) {
        result.add(dividerSizes[i]);
      }
    }
    return result;
  }

  double _getAvailableSpace(BoxConstraints constraints) {
    final totalSpace = constraints.maxForDirection(widget.direction);
    final dividerSpace = getDividerSpace(
      widget.children,
      controller.hiddenIndices,
    );

    return totalSpace - dividerSpace;
  }
}

class _PaneSlot extends StatelessWidget {
  const _PaneSlot({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Keeps panes whose size didn't change from repainting during a drag. Must
    // not size `child`: the shrink dry-layout measures it directly.
    return RepaintBoundary(child: child);
  }
}

class _ContainerLayout extends StatelessWidget {
  const _ContainerLayout({
    required this.direction,
    required this.resizable,
    required this.resizableChildren,
    required this.sizes,
    required this.hiddenIndices,
    required this.fixedSizes,
    required this.collapsing,
    required this.onComplete,
    required this.onResizeUpdate,
  });

  final Axis direction;
  final bool resizable;
  final List<ResizableChild> resizableChildren;
  final List<ResizableSize> sizes;
  final Set<int> hiddenIndices;
  final List<double>? fixedSizes;
  final bool collapsing;
  final ValueChanged<List<double>> onComplete;
  final void Function(int index, double delta) onResizeUpdate;

  Key? _dividerKey(int index) {
    final paneKey = resizableChildren[index].key;
    return paneKey == null ? null : ValueKey(('divider', paneKey));
  }

  @override
  Widget build(BuildContext context) {
    final lastIndex = resizableChildren.length - 1;
    final children = <Widget>[];

    for (var i = 0; i <= lastIndex; i++) {
      final child = resizableChildren[i];
      final hidden = hiddenIndices.contains(i);
      final scopedChild = HiddenChildScope(
        hidden: hidden,
        tickersEnabled: !hidden || collapsing,
        child: child.child,
      );
      children.add(_PaneSlot(key: child.key, child: scopedChild));

      if (i == lastIndex) continue;

      final dividerEnabled = resizable &&
          child.divider.enabled &&
          !isDividerHidden(hiddenIndices, i);
      children.add(
        ResizableContainerDivider(
          key: _dividerKey(i),
          config: child.divider,
          direction: direction,
          enabled: dividerEnabled,
          onResizeUpdate: (delta) => onResizeUpdate(i, delta),
        ),
      );
    }

    return ResizableLayout(
      direction: direction,
      onComplete: onComplete,
      sizes: sizes,
      resizableChildren: resizableChildren,
      hiddenIndices: hiddenIndices,
      fixedSizes: fixedSizes,
      children: children,
    );
  }
}

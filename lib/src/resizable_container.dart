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
import 'package:flutter_resizable_container/src/resizable_controller.dart';
import 'package:flutter_resizable_container/src/resizable_divider_line.dart';
import 'package:flutter_resizable_container/src/resizable_divider_overlay.dart';

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
    manager.setDirection(widget.direction);
    _prevHiddenIndices = Set.of(controller.hiddenIndices);
    controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant ResizableContainer oldWidget) {
    final controllerChanged = oldWidget.controller != widget.controller;
    final structuralChange =
        !oldWidget.children.hasSameStructureAs(widget.children);
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
      manager.initChildren(widget.children);
      _prevHiddenIndices = Set.of(controller.hiddenIndices);
    } else if (configChange) {
      manager.updateChildrenInPlace(widget.children);
    }

    if (directionChanged) {
      _animation.cancel();
    }

    if (!controllerChanged && cascadeChanged) {
      manager.setCascadeNegativeDelta(widget.cascadeNegativeDelta);
    }

    if ((!controllerChanged && structuralChange) || directionChanged) {
      manager.setNeedsLayout();
    }
    manager.setDirection(widget.direction);

    if (oldWidget.hideAnimation != widget.hideAnimation &&
        widget.hideAnimation == null) {
      _animation.reset();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    // The controller's state can outlive this container, so a remount must
    // still re-measure the shrink children this animation would have.
    if (_remeasureShrinkOnIdle) {
      manager.setNeedsLayout();
    }
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

    final hideAnimation = widget.hideAnimation;
    if (hideAnimation != null) {
      final revealed = _prevHiddenIndices.difference(newHidden);
      if (controller.needsLayout) {
        _beginHideAnimation(revealed: revealed);
      } else {
        _animateHiddenChange(revealed: revealed, animation: hideAnimation);
      }
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

  void _animateHiddenChange({
    required Set<int> revealed,
    required ResizableHideAnimation animation,
  }) {
    final from = _deriveFullSizesFromController(
      pixels: manager.pixelsBeforeHiddenChange,
      hiddenIndices: _prevHiddenIndices,
    );
    final to = _deriveFullSizesFromController();
    _animation
      ..beginCapture(from)
      ..startAnimation(target: to, animation: animation);

    final sizes = controller.sizes;
    final revealedShrink = revealed.any(
      (index) => index < sizes.length && sizes[index] is ResizableSizeShrink,
    );
    if (revealedShrink) {
      _remeasureShrinkOnIdle = true;
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

        final availableSpaceChanged = manager.setAvailableSpace(availableSpace);
        if (availableSpaceChanged && !controller.needsLayout) {
          _scheduleNotifyAfterResize();
        }

        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final isIdle = _animation.phase == HideAnimationPhase.idle;
            final layoutPending = isIdle && controller.needsLayout;
            final hiddenIndices = controller.hiddenIndices;
            final fixedSizes = _fixedSizesForPhase();
            // Stale while a layout pass is pending, which is why the overlay
            // ignores pointers until it completes.
            final overlaySizes = fixedSizes ?? _deriveFullSizesFromController();
            final dividerKeys = [
              for (var i = 0; i < widget.children.length - 1; i++)
                _dividerKey(widget.children, i),
            ];

            return Stack(
              fit: StackFit.passthrough,
              clipBehavior: Clip.none,
              children: [
                _ContainerLayout(
                  direction: widget.direction,
                  resizableChildren: widget.children,
                  sizes: controller.sizes,
                  hiddenIndices: hiddenIndices,
                  fixedSizes: fixedSizes,
                  collapsing: !isIdle,
                  onComplete: _scheduleSetRenderedSizes,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: layoutPending,
                    child: ResizableDividerOverlay(
                      direction: widget.direction,
                      dividers: widget.children.dividers,
                      dividerKeys: dividerKeys,
                      sizes: overlaySizes,
                      hiddenIndices: hiddenIndices,
                      resizable: widget.resizable,
                      onResizeUpdate: _onDividerDrag,
                    ),
                  ),
                ),
              ],
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

  void _scheduleNotifyAfterResize() {
    final scheduledController = controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // A pending layout ends in setRenderedSizes, which notifies on its own.
      final shouldNotify = mounted &&
          controller == scheduledController &&
          !controller.needsLayout;
      if (shouldNotify) {
        manager.notify();
      }
    });
  }

  List<double> _deriveFullSizesFromController({
    List<double>? pixels,
    Set<int>? hiddenIndices,
  }) {
    final childPixels = pixels ?? controller.pixels;
    final hidden = hiddenIndices ?? controller.hiddenIndices;
    final dividerSizes = dividerExtents(widget.children.dividers, hidden);
    final result = <double>[];
    for (var i = 0; i < widget.children.length; i++) {
      result.add(childPixels[i]);
      if (i < dividerSizes.length) {
        result.add(dividerSizes[i]);
      }
    }
    return result;
  }

  void _onDividerDrag(int dividerIndex, double delta) {
    // The pending capture callback would overwrite a drag made now.
    if (_animation.phase == HideAnimationPhase.capturing) return;

    // A re-measure would overwrite the drag once a later animation settles.
    _remeasureShrinkOnIdle = false;
    _animation.cancel();
    manager.adjustChildSize(index: dividerIndex, delta: delta);
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

Key? _dividerKey(List<ResizableChild> children, int index) {
  final paneKey = children[index].key;
  return paneKey == null ? null : ValueKey(('divider', paneKey));
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
    required this.resizableChildren,
    required this.sizes,
    required this.hiddenIndices,
    required this.fixedSizes,
    required this.collapsing,
    required this.onComplete,
  });

  final Axis direction;
  final List<ResizableChild> resizableChildren;
  final List<ResizableSize> sizes;
  final Set<int> hiddenIndices;
  final List<double>? fixedSizes;
  final bool collapsing;
  final ValueChanged<List<double>> onComplete;

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

      children.add(
        ResizableDividerLine(
          key: _dividerKey(resizableChildren, i),
          config: child.divider,
          direction: direction,
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

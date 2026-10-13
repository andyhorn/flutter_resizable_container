import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/extensions/resizable_children_ext.dart';
import 'package:flutter_resizable_container/src/layout/resizable_allocation.dart';
import 'package:flutter_resizable_container/src/resizable_divider_handle.dart';

/// Lays the interactive dividers over the panes at the positions the
/// underlying layout gives their line slots.
///
/// [sizes] alternates child and divider extents, as the layout receives them.
/// Each divider is keyed by the pane that precedes it, or matched by position
/// when that pane has no key. A divider whose neighbour is in
/// [hiddenIndices] stays mounted at zero extent, ignoring its
/// [ResizableDivider.hitSlop], and is disabled and excluded from semantics.
/// The key shared by the line and the interactive overlay of the divider that
/// follows `children[index]`, or `null` when that child has no key.
Key? dividerKey(List<ResizableChild> children, int index) {
  final paneKey = children[index].key;
  return paneKey == null ? null : ValueKey(('divider', paneKey));
}

class ResizableDividerOverlay extends StatelessWidget {
  const ResizableDividerOverlay({
    super.key,
    required this.direction,
    required this.children,
    required this.sizes,
    required this.hiddenIndices,
    required this.resizable,
    required this.onResizeUpdate,
    required this.positionAfter,
  });

  final Axis direction;
  final List<ResizableChild> children;
  final List<double> sizes;
  final Set<int> hiddenIndices;
  final bool resizable;
  final void Function(int dividerIndex, double delta) onResizeUpdate;

  /// The fraction of the total child size before divider `dividerIndex` once
  /// `delta` is applied.
  final double Function(int dividerIndex, double delta) positionAfter;

  @override
  Widget build(BuildContext context) {
    final dividers = children.dividers;
    final extents = [for (final size in sizes) math.max(0.0, size)];
    final offsets = _dividerOffsets(extents, dividers.length);
    final positioned = <Widget>[];
    for (var i = 0; i < dividers.length; i++) {
      final divider = dividers[i];
      final hidden = isDividerHidden(hiddenIndices, i);
      final slop = hidden ? 0.0 : divider.hitSlop;

      positioned.add(
        _DividerPosition(
          key: dividerKey(children, i),
          direction: direction,
          offset: offsets[i] - slop,
          extent: extents[i * 2 + 1] + 2 * slop,
          child: ExcludeSemantics(
            excluding: hidden,
            child: ResizableDividerHandle(
              config: divider,
              direction: direction,
              enabled: resizable && divider.enabled && !hidden,
              onResizeUpdate: (delta) => onResizeUpdate(i, delta),
              positionAfter: (delta) => positionAfter(i, delta),
            ),
          ),
        ),
      );
    }

    return Stack(clipBehavior: Clip.none, children: positioned);
  }

  /// Mirrors how the layout advances its cursor, so each divider starts where
  /// its line slot does.
  List<double> _dividerOffsets(List<double> extents, int dividerCount) {
    final offsets = <double>[];
    var cursor = 0.0;
    for (var i = 0; i < dividerCount; i++) {
      cursor += extents[i * 2];
      offsets.add(cursor);
      cursor += extents[i * 2 + 1];
    }
    return offsets;
  }
}

class _DividerPosition extends StatelessWidget {
  const _DividerPosition({
    super.key,
    required this.direction,
    required this.offset,
    required this.extent,
    required this.child,
  });

  final Axis direction;
  final double offset;
  final double extent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return switch (direction) {
      Axis.horizontal => PositionedDirectional(
          start: offset,
          width: extent,
          top: 0,
          bottom: 0,
          child: child,
        ),
      Axis.vertical => Positioned(
          top: offset,
          height: extent,
          left: 0,
          right: 0,
          child: child,
        ),
    };
  }
}

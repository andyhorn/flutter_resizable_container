import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/layout/resizable_allocation.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';

/// Lays the interactive dividers over the panes at the positions the
/// underlying layout gives their line slots.
///
/// [sizes] alternates child and divider extents, as the layout receives them.
/// [dividerKeys] holds the key for the divider that follows each child, or
/// `null` to match it by position. A divider whose neighbour is in
/// [hiddenIndices] stays mounted at zero extent and is disabled.
class ResizableDividerOverlay extends StatelessWidget {
  const ResizableDividerOverlay({
    super.key,
    required this.direction,
    required this.dividers,
    required this.dividerKeys,
    required this.sizes,
    required this.hiddenIndices,
    required this.resizable,
    required this.onResizeUpdate,
  });

  final Axis direction;
  final List<ResizableDivider> dividers;
  final List<Key?> dividerKeys;
  final List<double> sizes;
  final Set<int> hiddenIndices;
  final bool resizable;
  final void Function(int dividerIndex, double delta) onResizeUpdate;

  @override
  Widget build(BuildContext context) {
    final extents = [for (final size in sizes) math.max(0.0, size)];
    final offsets = _dividerOffsets(extents);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < dividers.length; i++)
          _DividerPosition(
            key: dividerKeys[i],
            direction: direction,
            offset: offsets[i],
            extent: extents[i * 2 + 1],
            child: ResizableContainerDivider(
              config: dividers[i],
              direction: direction,
              enabled: resizable &&
                  dividers[i].enabled &&
                  !isDividerHidden(hiddenIndices, i),
              onResizeUpdate: (delta) => onResizeUpdate(i, delta),
            ),
          ),
      ],
    );
  }

  /// Mirrors how the layout advances its cursor, so each divider starts where
  /// its line slot does.
  List<double> _dividerOffsets(List<double> extents) {
    final offsets = <double>[];
    var cursor = 0.0;
    for (var i = 0; i < dividers.length; i++) {
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

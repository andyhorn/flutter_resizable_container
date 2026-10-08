import 'package:flutter_resizable_container/src/extensions/iterable_ext.dart';
import 'package:flutter_resizable_container/src/extensions/num_ext.dart';
import 'package:flutter_resizable_container/src/resizable_size.dart';

/// Distributes [availableSpace] across the expand entries of [sizes] by flex.
///
/// Entries whose share violates their min or max are frozen at the clamped
/// value and the remaining space is redistributed among the rest. The result
/// maps the index in [sizes] of each expand entry to its resolved size.
Map<int, double> getExpandSizes(
  List<ResizableSize> sizes,
  double availableSpace,
) {
  final unfrozen = sizes.indicesWhere((size) => size is ResizableSizeExpand);
  final pending = unfrozen.toList();
  final resolved = <int, double>{};
  var remainingSpace = availableSpace;
  var remainingFlex = pending.map((index) => _flexAt(sizes, index)).sum();

  for (var pass = 0; pass < unfrozen.length; pass++) {
    final targets = _getTargets(
      sizes: sizes,
      indices: pending,
      space: remainingSpace,
      flex: remainingFlex,
    );
    final clamped = {
      for (final index in pending)
        index: clampToSize(targets[index]!, sizes[index]),
    };
    final totalViolation = _getTotalViolation(targets, clamped);

    // A NaN violation (unbounded space) matches no violator, so clamp the
    // targets as-is rather than leave them unassigned.
    if (totalViolation == 0 || totalViolation.isNaN) {
      return resolved..addAll(clamped);
    }

    final violators = pending.where(
      (index) => _isViolator(
        target: targets[index]!,
        clamped: clamped[index]!,
        totalViolation: totalViolation,
      ),
    );
    for (final index in violators.toList()) {
      resolved[index] = clamped[index]!;
      remainingSpace -= clamped[index]!;
      remainingFlex -= _flexAt(sizes, index);
    }
    pending.removeWhere(resolved.containsKey);
  }

  return resolved;
}

Map<int, double> _getTargets({
  required List<ResizableSize> sizes,
  required List<int> indices,
  required double space,
  required int flex,
}) {
  return {
    for (final index in indices)
      // flex 0 is only asserted against, so release builds can still get
      // here with flex == 0; return 0 instead of the NaN from 0/0.
      index: flex == 0 ? 0.0 : space * _flexAt(sizes, index) / flex,
  };
}

double _getTotalViolation(
  Map<int, double> targets,
  Map<int, double> clamped,
) {
  var total = 0.0;
  for (final entry in targets.entries) {
    total += clamped[entry.key]! - entry.value;
  }
  return total;
}

bool _isViolator({
  required double target,
  required double clamped,
  required double totalViolation,
}) {
  return totalViolation > 0 ? clamped > target : clamped < target;
}

int _flexAt(List<ResizableSize> sizes, int index) {
  return (sizes[index] as ResizableSizeExpand).flex;
}

/// Clamps [value] to the min/max bounds of [size].
double clampToSize(double value, ResizableSize size) {
  return value.clamp(size.min ?? 0, size.max ?? double.infinity);
}

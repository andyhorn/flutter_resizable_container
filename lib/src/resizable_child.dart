import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';

/// A child of a [ResizableContainer] that can be resized.
///
/// The [child] Widget will be displayed if [visible] is `true`.
///
/// The [size] will be used to determine the size of the child during the initial layout, resizing, and screen size changes.
///
/// The [divider] will be used to separate this child from the next child.
///
/// The [key] will be used to identify this child in the list of children.
class ResizableChild extends Equatable {
  /// Create a new instance of the [ResizableChild] class.
  const ResizableChild({
    required this.id,
    required this.child,
    this.key,
    this.size = const ResizableSize.expand(),
    this.divider = const ResizableDivider(),
    this.visible = true,
  });

  /// The (optional) key for this child Widget's container in the list.
  final Key? key;

  /// The unique identifier for this child.
  final String id;

  /// The size of the corresponding widget. May use a ratio of the
  /// available space, an absolute size in logical pixels, or it can
  /// auto-expand to fill available space.
  ///
  /// ```dart
  /// // Ratio of available space
  /// size: const ResizableSize.ratio(0.25);
  ///
  /// // Absolute size in logical pixels
  /// size: const ResizableSize.pixels(300);
  ///
  /// // Auto-fill available space
  /// size: const ResizableSize.expand(),
  ///
  /// // Conform to the child's intrinsic size
  /// size: const ResizableSize.shrink(),
  /// ```
  final ResizableSize size;

  /// The child [Widget] to be displayed.
  final Widget child;

  /// The divider configuration to be used after this child.
  ///
  /// If not provided, the default divider will be used.
  ///
  /// If this is the last child, the divider will not be used.
  final ResizableDivider divider;

  /// Whether or not the child is visible.
  ///
  /// If `false`, the child will not be displayed.
  ///
  /// Defaults to `true`.
  final bool visible;

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [size, key, child.key, child.runtimeType, visible];
}

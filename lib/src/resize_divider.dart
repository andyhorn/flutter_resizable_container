import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/src/resize_cursor.dart';

class ResizeDivider extends StatelessWidget {
  const ResizeDivider({
    super.key,
    required this.direction,
    required this.onResizeUpdate,
    this.showDivider = true,
  });

  final bool showDivider;
  final Axis direction;
  final void Function(double) onResizeUpdate;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (showDivider)
          direction == Axis.horizontal
              ? const VerticalDivider()
              : const Divider(),
        ResizeCursor(
          direction: direction,
          onResizeUpdate: onResizeUpdate,
        ),
      ],
    );
  }
}

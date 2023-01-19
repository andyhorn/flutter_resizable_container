import 'package:flutter/material.dart';

class ResizeDivider extends StatelessWidget {
  const ResizeDivider({
    super.key,
    required this.direction,
  });

  final Axis direction;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: direction == Axis.horizontal
          ? Alignment.centerRight
          : Alignment.bottomCenter,
      child: Transform.translate(
        offset: direction == Axis.horizontal
            ? const Offset(-4, 0)
            : const Offset(0, -4),
        child: direction == Axis.horizontal
            ? const VerticalDivider()
            : const Divider(),
      ),
    );
  }
}

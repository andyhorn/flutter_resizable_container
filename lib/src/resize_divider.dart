import 'package:flutter/material.dart';

class ResizeDivider extends StatelessWidget {
  const ResizeDivider({
    super.key,
    required this.constraints,
    required this.direction,
    required this.position,
  });

  final BoxConstraints constraints;
  final Axis direction;
  final double position;

  static const _dividerWidth = 6.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _getPositionLeft(),
      top: _getPositionTop(),
      height: _getPositionHeight(),
      width: _getPositionWidth(),
      child: direction == Axis.horizontal
          ? const VerticalDivider(
              width: _dividerWidth,
            )
          : const Divider(),
    );
  }

  double? _getPositionLeft() {
    return direction == Axis.horizontal ? position - (_dividerWidth / 2) : null;
  }

  double? _getPositionTop() {
    return direction == Axis.vertical ? position - (_dividerWidth / 2) : null;
  }

  double? _getPositionHeight() {
    return direction == Axis.horizontal ? constraints.maxHeight : null;
  }

  double? _getPositionWidth() {
    return direction == Axis.vertical ? constraints.maxWidth : null;
  }
}

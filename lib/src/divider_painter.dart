import 'dart:math';

import 'package:flutter/material.dart';

class DividerPainter extends CustomPainter {
  const DividerPainter({
    required this.color,
    required this.direction,
    required this.thickness,
    this.indent,
    this.endIndent,
  });

  final Axis direction;
  final double thickness;
  final Color color;
  final double? indent;
  final double? endIndent;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _getPath(size);
    final paint = _getPaint();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  Paint _getPaint() {
    return Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
  }

  Path _getPath(Size size) {
    final startingPoint = _getStartingPoint(size);
    final endingPoint = _getEndingPoint(size);

    return Path()
      ..moveTo(startingPoint.x, startingPoint.y)
      ..lineTo(endingPoint.x, endingPoint.y)
      ..close();
  }

  Point<double> _getStartingPoint(Size size) {
    if (direction == Axis.horizontal) {
      // If the direction is horizontal, the divider is a vertical line and the
      // "start" is at the top.
      //
      // The indent should be the lesser of the available height, the specified
      // indent, or 0.
      final indentAmount = min(size.height, indent ?? 0.0);
      return Point(size.width / 2, indentAmount);
    }

    // If the direction is vertical, the divider is a horizontal line and the
    // "start" is at the left.
    //
    // The indent should be the lesser of the available width, the specified
    // indent, or 0.
    final indentAmount = min(size.width, indent ?? 0.0);
    return Point(indentAmount, size.height / 2);
  }

  Point<double> _getEndingPoint(Size size) {
    if (direction == Axis.horizontal) {
      // If the direction is horizontal, the divider is a vertical line and the
      // "end" is at the bottom.
      //
      // The indent should be the available height minus the indent amount,
      // capped at a minimum of 0.
      final indentAmount = max(0.0, size.height - (endIndent ?? 0));
      return Point(size.width / 2, indentAmount);
    }

    // If the direction is vertical, the divider is a horizontal line and the
    // "end" is at the right.
    //
    // The indent should be the available width minus the indent amount, capped
    // at a minimum of 0.
    final indentAmount = max(0.0, size.width - (endIndent ?? 0));
    return Point(indentAmount, size.height / 2);
  }
}

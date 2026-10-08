import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/divider_painter.dart';
import 'package:flutter_resizable_container/src/extensions/divider_layout_ext.dart';

/// The visible, non-interactive part of a divider.
class ResizableDividerLine extends StatelessWidget {
  const ResizableDividerLine({
    super.key,
    required this.config,
    required this.direction,
  });

  final ResizableDivider config;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: config.alignmentFor(direction),
          child: CustomPaint(
            size: config.sizeFor(direction, constraints),
            painter: DividerPainter(
              direction: direction,
              color: config.color ?? Theme.of(context).dividerColor,
              thickness: config.thickness,
              crossAxisAlignment: config.crossAxisAlignment,
              length: config.length,
              mainAxisAlignment: config.mainAxisAlignment,
              padding: config.padding,
            ),
          ),
        );
      },
    );
  }
}

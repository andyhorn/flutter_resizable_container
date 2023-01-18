import 'package:flutter/material.dart';

class ResizableChildData {
  const ResizableChildData({
    required this.child,
    required this.startingRatio,
    this.maxSize,
    this.minSize,
  });

  final Widget child;
  final double? maxSize;
  final double? minSize;
  final double startingRatio;
}

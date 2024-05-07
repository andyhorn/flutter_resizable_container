/// Controls the sizing parameters for the [child] Widget.
class ResizableChildData {
  /// Create a new instance of the [ResizableChildData] class.
  const ResizableChildData({
    this.startingRatio,
    this.maxSize,
    this.minSize,
  }) : assert(
          startingRatio == null || (startingRatio >= 0 && startingRatio <= 1),
          'The starting ratio must be null or between 0 and 1, inclusive',
        );

  /// The starting size (as a ratio of available space) of the
  /// corresponding widget.
  final double? startingRatio;

  /// The (optional) maximum size (in px) of this child Widget.
  final double? maxSize;

  /// The (optional) minimum size (in px) of this child Widget.
  final double? minSize;

  @override
  String toString() =>
      'ResizableChildData(startingRatio: $startingRatio, maxSize: $maxSize, minSize: $minSize)';
}

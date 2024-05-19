sealed class ResizableSize {
  const ResizableSize._(this.value);

  factory ResizableSize.pixels(double pixels) => ResizableSizePixels._(pixels);
  factory ResizableSize.ratio(double ratio) => ResizableSizeRatio._(ratio);

  final double value;
}

final class ResizableSizePixels extends ResizableSize {
  const ResizableSizePixels._(super.pixels)
      : assert(pixels >= 0, 'value must be greater than or equal to 0'),
        super._();

  @override
  String toString() => 'ResizableSize(pixels: $value)';

  @override
  operator ==(Object other) =>
      other is ResizableSizePixels && other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

final class ResizableSizeRatio extends ResizableSize {
  const ResizableSizeRatio._(super.ratio)
      : assert(ratio >= 0 && ratio <= 1,
            'value must be between 0 and 1, inclusively'),
        super._();

  @override
  String toString() => 'ResizableSize(ratio: $value)';

  @override
  operator ==(Object other) =>
      other is ResizableSizeRatio && other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

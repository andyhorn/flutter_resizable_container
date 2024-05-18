sealed class ResizableStartingSize {
  const ResizableStartingSize._(this.value);

  factory ResizableStartingSize.pixels(double pixels) =>
      ResizableStartingSizePixels._(pixels);
  factory ResizableStartingSize.ratio(double ratio) =>
      ResizableStartingSizeRatio._(ratio);

  final double value;
}

final class ResizableStartingSizePixels extends ResizableStartingSize {
  const ResizableStartingSizePixels._(super.pixels)
      : assert(pixels >= 0, 'value must be greater than or equal to 0'),
        super._();

  @override
  String toString() => 'ResizableStartingSize(pixels: $value)';

  @override
  operator ==(Object other) =>
      other is ResizableStartingSizePixels && other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

final class ResizableStartingSizeRatio extends ResizableStartingSize {
  const ResizableStartingSizeRatio._(super.ratio)
      : assert(ratio >= 0 && ratio <= 1,
            'value must be between 0 and 1, inclusively'),
        super._();

  @override
  String toString() => 'ResizableStartingSize(ratio: $value)';

  @override
  operator ==(Object other) =>
      other is ResizableStartingSizeRatio && other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

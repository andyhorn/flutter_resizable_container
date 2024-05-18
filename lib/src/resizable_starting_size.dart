sealed class ResizableStartingSize {
  const ResizableStartingSize._(this.value);

  factory ResizableStartingSize.pixels(double pixels) =>
      ResizableStartingSizePixels._(pixels);
  factory ResizableStartingSize.ratio(double ratio) =>
      ResizableStartingSizeRatio._(ratio);

  final double value;
}

final class ResizableStartingSizePixels extends ResizableStartingSize {
  const ResizableStartingSizePixels._(double pixels) : super._(pixels);

  @override
  String toString() => 'ResizableStartingSize(pixels: $value)';

  @override
  operator ==(Object other) =>
      other is ResizableStartingSizePixels && other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

final class ResizableStartingSizeRatio extends ResizableStartingSize {
  const ResizableStartingSizeRatio._(double ratio) : super._(ratio);

  @override
  String toString() => 'ResizableStartingSize(ratio: $value)';

  @override
  operator ==(Object other) =>
      other is ResizableStartingSizeRatio && other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

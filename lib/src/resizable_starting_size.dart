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
}

final class ResizableStartingSizeRatio extends ResizableStartingSize {
  const ResizableStartingSizeRatio._(double ratio) : super._(ratio);
}

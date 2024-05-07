/// The starting size of a resizable widget.
///
/// This can either be a [StartingRatio] or a [StartingPixels].
sealed class StartingSize {
  const StartingSize._();

  factory StartingSize.ratio(double ratio) => StartingRatio._(ratio);
  factory StartingSize.pixels(double pixels) => StartingPixels._(pixels);
}

/// The starting size of a widget represented as a portion of the available
/// space. Must be between 0 and 1.
final class StartingRatio extends StartingSize {
  const StartingRatio._(this.ratio)
      : assert(
          ratio >= 0 && ratio <= 1,
          'Ratio must be between 0 and 1, inclusive',
        ),
        super._();

  final double ratio;
}

/// The starting size of a widget in logical pixels.
final class StartingPixels extends StartingSize {
  const StartingPixels._(this.pixels) : super._();
  final double pixels;
}

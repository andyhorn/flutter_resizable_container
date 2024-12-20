sealed class ResizableSize {
  const ResizableSize._();

  const factory ResizableSize.pixels(double pixels) = ResizableSizePixels;
  const factory ResizableSize.ratio(double ratio) = ResizableSizeRatio;
  const factory ResizableSize.expand({int flex}) = ResizableSizeExpand;
  const factory ResizableSize.shrink() = ResizableSizeShrink;
}

final class ResizableSizePixels extends ResizableSize {
  const ResizableSizePixels(this.pixels)
      : assert(pixels >= 0, 'pixels must be greater than or equal to 0'),
        super._();

  final double pixels;

  @override
  String toString() => 'ResizableSizePixels($pixels)';

  @override
  operator ==(Object other) =>
      other is ResizableSizePixels && other.pixels == pixels;

  @override
  int get hashCode => pixels.hashCode;
}

final class ResizableSizeRatio extends ResizableSize {
  const ResizableSizeRatio(this.ratio)
      : assert(ratio >= 0, 'ratio must be greater than or equal to 0'),
        assert(ratio <= 1, 'ratio must be less than or equal to 1'),
        super._();

  final double ratio;

  @override
  String toString() => 'ResizableSizeRatio($ratio)';

  @override
  operator ==(Object other) =>
      other is ResizableSizeRatio && other.ratio == ratio;

  @override
  int get hashCode => ratio.hashCode;
}

final class ResizableSizeExpand extends ResizableSize {
  const ResizableSizeExpand({this.flex = 1})
      : assert(flex > 0, 'flex must be greater than 0'),
        super._();

  final int flex;

  @override
  String toString() => 'ResizableSizeExpand(flex: $flex)';

  @override
  operator ==(Object other) =>
      other is ResizableSizeExpand && other.flex == flex;

  @override
  int get hashCode => flex.hashCode;
}

final class ResizableSizeShrink extends ResizableSize {
  const ResizableSizeShrink() : super._();

  @override
  String toString() => 'ResizableSizeShrink()';
}

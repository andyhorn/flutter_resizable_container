enum SizeType {
  ratio,
  pixels,
}

final class ResizableSize {
  const ResizableSize.pixels(double pixels)
      // ignore: prefer_initializing_formals
      : pixels = pixels,
        ratio = null,
        type = SizeType.pixels,
        assert(pixels >= 0, 'Value cannot be less than 0.');

  const ResizableSize.ratio(double ratio)
      // ignore: prefer_initializing_formals
      : ratio = ratio,
        pixels = null,
        type = SizeType.ratio,
        assert(
          ratio >= 0 && ratio <= 1,
          'Value must be between 0 and 1, inclusive.',
        );

  final double? ratio;
  final double? pixels;
  final SizeType type;

  double get value => switch (type) {
        SizeType.ratio => ratio!,
        SizeType.pixels => pixels!,
      };

  @override
  String toString() => 'ResizableSize(type: $type, value: $value)';

  @override
  operator ==(Object other) =>
      other is ResizableSize && other.type == type && other.value == value;

  @override
  int get hashCode => Object.hash(type, value);
}

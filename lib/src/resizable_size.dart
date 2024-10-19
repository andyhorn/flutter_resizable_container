enum SizeType {
  ratio,
  pixels,
  expand,
  shrink,
}

final class ResizableSize {
  const ResizableSize.pixels(double pixels)
      // ignore: prefer_initializing_formals
      : _value = pixels,
        type = SizeType.pixels,
        assert(pixels >= 0, 'Value cannot be less than 0.');

  const ResizableSize.ratio(double ratio)
      // ignore: prefer_initializing_formals
      : _value = ratio,
        type = SizeType.ratio,
        assert(
          ratio >= 0 && ratio <= 1,
          'Value must be between 0 and 1, inclusive.',
        );

  const ResizableSize.expand({int flex = 1})
      : _value = flex,
        type = SizeType.expand,
        assert(flex > 0, 'Flex value must be greater than 0.');

  const ResizableSize.shrink()
      : _value = 0,
        type = SizeType.shrink;

  final num _value;
  final SizeType type;

  double get value => _value.toDouble();
  bool get isRatio => type == SizeType.ratio;
  bool get isPixels => type == SizeType.pixels;
  bool get isExpand => type == SizeType.expand;
  bool get isShrink => type == SizeType.shrink;

  @override
  String toString() => 'ResizableSize(type: $type, value: $_value)';

  @override
  operator ==(Object other) =>
      other is ResizableSize && other.type == type && other._value == _value;

  @override
  int get hashCode => Object.hash(type, _value);
}

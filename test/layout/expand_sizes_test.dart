import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/layout/expand_sizes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getExpandSizes', () {
    test('returns an empty map when there are no expand sizes', () {
      final result = getExpandSizes(
        const [ResizableSize.pixels(100), ResizableSize.ratio(0.5)],
        300,
      );

      expect(result, isEmpty);
    });

    test('splits by flex when nothing is constrained', () {
      final result = getExpandSizes(
        const [ResizableSize.expand(), ResizableSize.expand(flex: 3)],
        400,
      );

      expect(result, {0: 100, 1: 300});
    });

    test('only includes expand indices', () {
      final result = getExpandSizes(
        const [
          ResizableSize.pixels(100),
          ResizableSize.expand(),
          ResizableSize.shrink(),
          ResizableSize.expand(),
        ],
        200,
      );

      expect(result, {1: 100, 3: 100});
    });

    test('redistributes the remainder after a max violation', () {
      final result = getExpandSizes(
        const [
          ResizableSize.expand(max: 50),
          ResizableSize.expand(),
          ResizableSize.expand(flex: 2),
        ],
        400,
      );

      expect(result[0], 50);
      expect(result[1], moreOrLessEquals(350 / 3));
      expect(result[2], moreOrLessEquals(700 / 3));
    });

    test('redistributes the remainder after a min violation', () {
      final result = getExpandSizes(
        const [
          ResizableSize.expand(min: 200),
          ResizableSize.expand(),
          ResizableSize.expand(flex: 2),
        ],
        400,
      );

      expect(result[0], 200);
      expect(result[1], moreOrLessEquals(200 / 3));
      expect(result[2], moreOrLessEquals(400 / 3));
    });

    test('freezes only the net violation direction', () {
      final result = getExpandSizes(
        const [
          ResizableSize.expand(flex: 3, max: 145),
          ResizableSize.expand(flex: 3, min: 283),
          ResizableSize.expand(flex: 2, max: 196),
        ],
        488,
      );

      expect(result, {0: 123, 1: 283, 2: 82});
    });

    test('ends at the minimums when space is too small', () {
      final result = getExpandSizes(
        const [
          ResizableSize.expand(min: 80),
          ResizableSize.expand(min: 60),
        ],
        100,
      );

      expect(result, {0: 80, 1: 60});
    });

    test('clamps targets without freezing when space is unbounded', () {
      final result = getExpandSizes(
        const [
          ResizableSize.expand(max: 50),
          ResizableSize.expand(),
        ],
        double.infinity,
      );

      expect(result[0], 50);
      expect(result[1], double.infinity);
    });
  });
}

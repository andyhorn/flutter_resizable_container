import 'package:flutter_resizable_container/src/resizable_size.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(ResizableSize, () {
    group(ResizableSizePixels, () {
      group('constructor', () {
        test('throws an error if the value is less than 0', () {
          expect(() => ResizableSize.pixels(-1), throwsAssertionError);
        });

        test('does not throw an error for a size of 0', () {
          expect(() => ResizableSize.pixels(0), isNot(throwsA(anything)));
        });
      });

      group('equality', () {
        test('returns false for a different type', () {
          final ratio = ResizableSize.ratio(0.5);
          final pixel = ResizableSize.pixels(100);

          expect(ratio == pixel, isFalse);
        });

        test('returns false for a different value', () {
          expect(
            ResizableSize.pixels(100) == ResizableSize.pixels(101),
            isFalse,
          );
        });

        test('returns true for the same value', () {
          expect(
            ResizableSize.pixels(100) == ResizableSize.pixels(100),
            isTrue,
          );
        });
      });
    });

    group(ResizableSizeRatio, () {
      group('equality', () {
        test('returns false for a different value', () {
          expect(
            ResizableSize.ratio(0.5) == ResizableSize.ratio(0.6),
            isFalse,
          );
        });

        test('returns true for the same value', () {
          expect(
            ResizableSize.ratio(0.5) == ResizableSize.ratio(0.5),
            isTrue,
          );
        });
      });
    });
  });
}

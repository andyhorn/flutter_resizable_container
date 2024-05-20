import 'package:flutter_resizable_container/src/resizable_size.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(ResizableSize, () {
    group('constructor', () {
      group('ratio', () {
        test('throws if the value is less than 0', () {
          expect(() => ResizableSize.ratio(-1), throwsAssertionError);
        });

        test('throws if the value is greater than 1', () {
          expect(() => ResizableSize.ratio(1.1), throwsAssertionError);
        });

        test('does not throw for a value of 0', () {
          expect(() => const ResizableSize.ratio(0), isNot(throwsA(anything)));
        });

        test('does not throw for a value of 1', () {
          expect(() => const ResizableSize.ratio(1), isNot(throwsA(anything)));
        });
      });

      group('pixels', () {
        test('throws for a value less than 0', () {
          expect(() => ResizableSize.pixels(-1), throwsAssertionError);
        });

        test('does not throw for a value of 0', () {
          expect(() => const ResizableSize.pixels(0), isNot(throwsA(anything)));
        });
      });

      group('equality', () {
        test('returns true for equal objects', () {
          expect(
            const ResizableSize.pixels(1) == const ResizableSize.pixels(1),
            isTrue,
          );
        });

        test('returns false for different objects', () {
          expect(
            const ResizableSize.pixels(1) == const ResizableSize.ratio(1),
            isFalse,
          );
        });

        test('returns false for similar objects with different values', () {
          expect(
            const ResizableSize.pixels(1) == const ResizableSize.pixels(2),
            isFalse,
          );
        });
      });
    });
  });
}

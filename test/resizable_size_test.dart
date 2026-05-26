import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/src/resizable_size.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

        group('pixels', () {
          test('returns false when min differs', () {
            expect(
              const ResizableSize.pixels(1, min: 10) ==
                  const ResizableSize.pixels(1, min: 20),
              isFalse,
            );
          });

          test('returns false when max differs', () {
            expect(
              const ResizableSize.pixels(1, max: 100) ==
                  const ResizableSize.pixels(1, max: 200),
              isFalse,
            );
          });

          test('returns true when pixels, min, and max all match', () {
            expect(
              const ResizableSize.pixels(1, min: 10, max: 100) ==
                  const ResizableSize.pixels(1, min: 10, max: 100),
              isTrue,
            );
          });

          test('hashCode differs when min/max differ', () {
            expect(
              const ResizableSize.pixels(1, min: 10).hashCode ==
                  const ResizableSize.pixels(1, min: 20).hashCode,
              isFalse,
            );
          });
        });

        group('ratio', () {
          test('returns false when min differs', () {
            expect(
              const ResizableSize.ratio(0.5, min: 10) ==
                  const ResizableSize.ratio(0.5, min: 20),
              isFalse,
            );
          });

          test('returns false when max differs', () {
            expect(
              const ResizableSize.ratio(0.5, max: 100) ==
                  const ResizableSize.ratio(0.5, max: 200),
              isFalse,
            );
          });

          test('returns true when ratio, min, and max all match', () {
            expect(
              const ResizableSize.ratio(0.5, min: 10, max: 100) ==
                  const ResizableSize.ratio(0.5, min: 10, max: 100),
              isTrue,
            );
          });

          test('hashCode differs when min/max differ', () {
            expect(
              const ResizableSize.ratio(0.5, min: 10).hashCode ==
                  const ResizableSize.ratio(0.5, min: 20).hashCode,
              isFalse,
            );
          });
        });

        group('expand', () {
          test('returns false when min differs', () {
            expect(
              const ResizableSize.expand(min: 10) ==
                  const ResizableSize.expand(min: 20),
              isFalse,
            );
          });

          test('returns false when max differs', () {
            expect(
              const ResizableSize.expand(max: 100) ==
                  const ResizableSize.expand(max: 200),
              isFalse,
            );
          });

          test('returns true when flex, min, and max all match', () {
            expect(
              const ResizableSize.expand(flex: 2, min: 10, max: 100) ==
                  const ResizableSize.expand(flex: 2, min: 10, max: 100),
              isTrue,
            );
          });

          test('hashCode differs when min/max differ', () {
            expect(
              const ResizableSize.expand(min: 10).hashCode ==
                  const ResizableSize.expand(min: 20).hashCode,
              isFalse,
            );
          });
        });

        group('shrink', () {
          test('returns true for two default shrink instances', () {
            expect(
              const ResizableSize.shrink() == const ResizableSize.shrink(),
              isTrue,
            );
          });

          test('returns false when min differs', () {
            expect(
              const ResizableSize.shrink(min: 10) ==
                  const ResizableSize.shrink(min: 20),
              isFalse,
            );
          });

          test('returns false when max differs', () {
            expect(
              const ResizableSize.shrink(max: 100) ==
                  const ResizableSize.shrink(max: 200),
              isFalse,
            );
          });

          test('returns true when min and max match', () {
            expect(
              const ResizableSize.shrink(min: 10, max: 100) ==
                  const ResizableSize.shrink(min: 10, max: 100),
              isTrue,
            );
          });

          test('hashCode matches for equal instances', () {
            expect(
              const ResizableSize.shrink(min: 10, max: 100).hashCode ==
                  const ResizableSize.shrink(min: 10, max: 100).hashCode,
              isTrue,
            );
          });
        });
      });
    });
  });
}

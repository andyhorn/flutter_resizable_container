import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(ResizableDivider, () {
    group('thickness', () {
      test('must be greater than 0', () {
        expect(() => ResizableDivider(thickness: 0), throwsAssertionError);
      });

      test('accepts greater than 0', () {
        expect(
          () => const ResizableDivider(thickness: 1),
          isNot(throwsAssertionError),
        );
      });
    });

    group('size', () {
      test('throws if less than thickness', () {
        expect(
          () => ResizableDivider(thickness: 1, size: 0.5),
          throwsAssertionError,
        );
      });

      test('does not throw if the same as thickness', () {
        expect(
          () => const ResizableDivider(thickness: 1, size: 1),
          isNot(throwsAssertionError),
        );
      });

      test('does not throw if greater than thickness', () {
        expect(
          () => const ResizableDivider(thickness: 1, size: 2),
          isNot(throwsAssertionError),
        );
      });
    });
  });
}

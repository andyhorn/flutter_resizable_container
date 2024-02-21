import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(ResizableController, () {
    late ResizableController controller;

    setUp(() {
      controller = ResizableController();
    });

    tearDown(() => controller.dispose());

    group('ratios', () {
      setUp(() {
        controller.availableSpace = 100;
        controller.sizes.addAll([10, 10, 25, 25, 30]);
      });

      test('returns the ratios of all the children', () {
        expect(controller.ratios, [0.1, 0.1, 0.25, 0.25, 0.3]);
      });
    });

    group('setRatios', () {
      setUp(() {
        controller.availableSpace = 100;
        controller.sizes.addAll([10, 10, 25, 25, 30]);
      });

      test('a list with the wrong length throws an error', () {
        expect(
          () => controller.setRatios([0.1, 0.1, 0.25, 0.25]),
          throwsA(isA<ArgumentError>().having(
            (error) => error.message,
            'Message',
            'Ratios list must be equal to the number of children',
          )),
        );
      });

      test('a list that does not add up to 1.0 throws an error', () {
        expect(
          () => controller.setRatios([0.1, 0.1, 0.25, 0.3, 0.3]),
          throwsA(isA<ArgumentError>().having(
            (error) => error.message,
            'Message',
            'The sum of the ratios must equal 1',
          )),
        );
      });

      test('setting the ratios updates the sizes', () {
        expect(controller.sizes, [10, 10, 25, 25, 30]);
        controller.setRatios([0.2, 0.2, 0.2, 0.2, 0.2]);
        expect(controller.sizes, [20, 20, 20, 20, 20]);
      });

      test('setting the ratios updates listeners', () {
        var didUpdate = false;
        controller.addListener(() {
          didUpdate = true;
        });
        controller.setRatios([0.2, 0.2, 0.2, 0.2, 0.2]);
        expect(didUpdate, isTrue);
      });
    });
  });
}

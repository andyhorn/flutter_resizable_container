import 'package:flutter/material.dart';
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
        controller.setChildren(
          const [
            ResizableChild(
              startingRatio: 0.1,
              child: SizedBox(),
            ),
            ResizableChild(
              startingRatio: 0.1,
              child: SizedBox(),
            ),
            ResizableChild(
              startingRatio: 0.25,
              child: SizedBox(),
            ),
            ResizableChild(
              startingRatio: 0.25,
              child: SizedBox(),
            ),
            ResizableChild(
              startingRatio: 0.3,
              child: SizedBox(),
            ),
          ],
        );

        controller.availableSpace = 1000;
      });

      test('returns the ratios of all the children', () {
        expect(controller.ratios, [0.1, 0.1, 0.25, 0.25, 0.3]);
      });

      test('changes the ratios', () {
        controller.ratios = [0.2, 0.2, 0.2, 0.2, 0.2];
        expect(controller.sizes, equals([200, 200, 200, 200, 200]));
      });

      test('throws an error if the list is the wrong length', () {
        expect(
          () => controller.ratios = [0.2, 0.2, 0.2],
          throwsArgumentError,
        );
      });

      test('throws an error if any ratio is less than 0', () {
        expect(
          () => controller.ratios = [0.2, 0.2, -0.2, 0.2, 0.2],
          throwsArgumentError,
        );
      });

      test('throws an error if any ratio is greater than 1', () {
        expect(
          () => controller.ratios = [0.2, 0.2, 1.2, 0.2, 0.2],
          throwsArgumentError,
        );
      });

      test('throws an error if the sum of all ratios is greater than 1.0', () {
        expect(
          () => controller.ratios = [0.2, 0.5, 0.2, 0.2, 0.2],
          throwsArgumentError,
        );
      });

      test('updates listeners', () {
        bool didUpdate = false;
        controller.addListener(() {
          didUpdate = true;
        });

        controller.ratios = [0.2, 0.2, 0.2, 0.2, 0.2];

        expect(didUpdate, isTrue);
      });
    });
  });
}

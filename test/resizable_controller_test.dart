import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(ResizableController, () {
    late ResizableController controller;

    setUp(() {
      controller = ResizableController();
    });

    tearDown(() => controller.dispose());

    group('.sizes', () {
      setUp(() {
        controller.setChildren(const [
          ResizableChild(
            startingSize: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            startingSize: ResizableSize.pixels(200),
            child: SizedBox.shrink(),
          ),
        ]);

        controller.setAvailableSpace(300);
      });

      test('returns a list of sizes', () {
        expect(controller.sizes, equals([100, 200]));
      });
    });

    group('.ratios', () {
      setUp(() {
        controller.setChildren(const [
          ResizableChild(
            startingSize: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            startingSize: ResizableSize.pixels(200),
            child: SizedBox.shrink(),
          ),
        ]);

        controller.setAvailableSpace(300);
      });

      test('returns a list of ratios', () {
        expect(controller.ratios, equals([1 / 3, 2 / 3]));
      });
    });

    group('#setAvailableSpace', () {
      group('when the new value is the same', () {
        setUp(() {
          controller.setChildren(const [
            ResizableChild(
              startingSize: ResizableSize.pixels(100),
              child: SizedBox.shrink(),
            ),
            ResizableChild(
              startingSize: ResizableSize.pixels(200),
              child: SizedBox.shrink(),
            ),
          ]);

          controller.setAvailableSpace(100);
        });

        test('does not notify listeners', () {
          var notified = false;
          controller.addListener(() => notified = true);

          controller.setAvailableSpace(100);

          expect(notified, isFalse);
        });
      });

      group('when setting the value for the first time', () {
        setUp(() {
          controller.setChildren(const [
            ResizableChild(
              startingSize: ResizableSize.pixels(100),
              child: SizedBox.shrink(),
            ),
            ResizableChild(
              startingSize: ResizableSize.ratio(1 / 2),
              child: SizedBox.shrink(),
            ),
            ResizableChild(child: SizedBox.shrink()),
          ]);
        });

        test('sets sizes based on child starting size', () {
          controller.setAvailableSpace(300);
          expect(controller.sizes, equals([100, 100, 100]));
        });

        test('notifies listeners', () {
          var notified = false;
          controller.addListener(() => notified = true);
          controller.setAvailableSpace(300);
          expect(notified, isTrue);
        });
      });

      group('when updating the available space', () {
        setUp(() {
          controller.setChildren(const [
            ResizableChild(
              startingSize: ResizableSize.pixels(100),
              child: SizedBox.shrink(),
            ),
            ResizableChild(
              startingSize: ResizableSize.ratio(1 / 2),
              child: SizedBox.shrink(),
            ),
            ResizableChild(child: SizedBox.shrink()),
          ]);

          controller.setAvailableSpace(300);
        });

        test('adjusts child sizes', () {
          controller.setAvailableSpace(600);
          expect(controller.sizes, equals([200, 200, 200]));
        });

        test('notifies listeners', () {
          var notified = false;
          controller.addListener(() => notified = true);
          controller.setAvailableSpace(600);
          expect(notified, isTrue);
        });
      });
    });

    group('#setChildren', () {
      test('sets the list of ResizableChild', () {
        controller.setChildren(const [
          ResizableChild(
            startingSize: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
        ]);

        expect(
          ResizableControllerTestHelper.getChildren(controller),
          equals(
            const [
              ResizableChild(
                startingSize: ResizableSize.pixels(100),
                child: SizedBox.shrink(),
              ),
            ],
          ),
        );
      });

      test('does not notify listeners', () {
        var notified = false;
        controller.addListener(() => notified = true);
        controller.setChildren(const [
          ResizableChild(
            startingSize: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
        ]);
        expect(notified, isFalse);
      });
    });

    group('#updateChildren', () {
      setUp(() {
        controller.setChildren(const [
          ResizableChild(
            startingSize: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            startingSize: null,
            child: SizedBox.shrink(),
          ),
        ]);

        controller.setAvailableSpace(200);
      });

      test('sets the list of children', () {
        controller.updateChildren(const [
          ResizableChild(
            startingSize: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            startingSize: null,
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            startingSize: null,
            child: SizedBox.shrink(),
          ),
        ]);

        expect(
          ResizableControllerTestHelper.getChildren(controller).length,
          equals(3),
        );
      });

      test('updates children sizes', () {
        controller.updateChildren(const [
          ResizableChild(
            startingSize: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            startingSize: null,
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            startingSize: null,
            child: SizedBox.shrink(),
          ),
        ]);

        expect(controller.sizes, equals([100, 50, 50]));
      });

      test('notifies listeners', () {
        var notified = false;
        controller.addListener(() => notified = true);
        controller.updateChildren(const [
          ResizableChild(
            startingSize: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            startingSize: null,
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            startingSize: null,
            child: SizedBox.shrink(),
          ),
        ]);

        expect(notified, isTrue);
      });
    });

    group('#adjustChildSize', () {
      setUp(() {
        controller.setChildren(const [
          ResizableChild(
            startingSize: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            startingSize: null,
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            startingSize: null,
            child: SizedBox.shrink(),
          ),
        ]);

        controller.setAvailableSpace(200);
      });

      group('when increasing the size', () {
        test('increases the size of the target child', () {
          controller.adjustChildSize(index: 1, delta: 10);
          expect(controller.sizes[1], equals(60));
        });

        test('decreases the size of the adjacent child', () {
          controller.adjustChildSize(index: 1, delta: 10);
          expect(controller.sizes[2], equals(40));
        });

        test('notifies listeners', () {
          var notified = false;
          controller.addListener(() => notified = true);
          controller.adjustChildSize(index: 1, delta: 10);
          expect(notified, isTrue);
        });
      });
    });

    group('#setSizes', () {
      setUp(() {
        controller.setChildren(const [
          ResizableChild(
            startingSize: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            startingSize: null,
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            startingSize: null,
            child: SizedBox.shrink(),
          ),
        ]);

        controller.setAvailableSpace(200);
      });

      group('when the list is the wrong length', () {
        test('throws argument error', () {
          expect(
            () => controller.setSizes(const [
              ResizableSize.pixels(100),
              ResizableSize.pixels(100),
            ]),
            throwsArgumentError,
          );
        });
      });

      group('when the number of pixels exceeds the available space', () {
        test('throws an argument error', () {
          expect(
            () => controller.setSizes(const [
              ResizableSize.pixels(150),
              ResizableSize.pixels(150),
              ResizableSize.pixels(150),
            ]),
            throwsArgumentError,
          );
        });
      });

      group('when the ratio sum exceeds 1', () {
        test('throws an argument error', () {
          expect(
            () => controller.setSizes(const [
              ResizableSize.ratio(0.5),
              ResizableSize.ratio(0.5),
              ResizableSize.ratio(0.5),
            ]),
            throwsArgumentError,
          );
        });
      });

      test('sets child sizes', () {
        controller.setSizes(const [
          ResizableSize.pixels(100),
          ResizableSize.ratio(0.5),
          null,
        ]);

        expect(controller.sizes, equals([100, 50, 50]));
      });
    });
  });
}

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group(ResizableController, () {
    late ResizableController controller;
    late ResizableControllerManager manager;

    setUp(() {
      controller = ResizableController();
      manager = ResizableControllerManager(controller);
    });

    tearDown(() => controller.dispose());

    group('.pixels', () {
      setUp(() {
        controller.setChildren(const [
          ResizableChild(
            size: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            size: ResizableSize.pixels(200),
            child: SizedBox.shrink(),
          ),
        ]);

        fakeAsync((async) {
          manager.setAvailableSpace(300);
          manager.setRenderedSizes([100, 200]);
          async.flushTimers();
        });
      });

      test('returns a list of pixel sizes', () {
        expect(controller.pixels, equals([100, 200]));
      });
    });

    group('.ratios', () {
      setUp(() {
        controller.setChildren(const [
          ResizableChild(
            size: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            size: ResizableSize.pixels(200),
            child: SizedBox.shrink(),
          ),
        ]);

        fakeAsync((async) {
          manager.setAvailableSpace(300);
          manager.setRenderedSizes([100, 200]);
          async.flushTimers();
        });
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
              size: ResizableSize.pixels(100),
              child: SizedBox.shrink(),
            ),
            ResizableChild(
              size: ResizableSize.pixels(200),
              child: SizedBox.shrink(),
            ),
          ]);

          fakeAsync((async) {
            manager.setAvailableSpace(300);
            manager.setRenderedSizes([100, 200]);
            async.flushTimers();
          });
        });

        test('does not notify listeners', () {
          var notified = false;
          controller.addListener(() => notified = true);

          manager.setAvailableSpace(300);

          expect(notified, isFalse);
        });
      });

      group('when updating the available space', () {
        setUp(() {
          controller.setChildren(const [
            ResizableChild(
              size: ResizableSize.pixels(100),
              child: SizedBox.shrink(),
            ),
            ResizableChild(
              size: ResizableSize.ratio(1 / 2),
              child: SizedBox.shrink(),
            ),
            ResizableChild(child: SizedBox.shrink()),
          ]);

          fakeAsync((async) {
            manager.setAvailableSpace(300);
            manager.setRenderedSizes([100, 150, 50]);
          });
        });

        test('adjusts child sizes', () {
          // only the "expandable" child (last) should change
          final expected = [...controller.pixels];
          expected.last += 300;

          manager.setAvailableSpace(600);
          expect(controller.pixels, equals(expected));
        });

        test('does not notify listeners', () {
          var notified = false;
          controller.addListener(() => notified = true);
          manager.setAvailableSpace(600);
          expect(notified, isFalse);
        });
      });
    });

    group('#setChildren', () {
      test('sets the list of ResizableChild', () {
        controller.setChildren(const [
          ResizableChild(
            size: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
        ]);

        expect(
          ResizableControllerTestHelper.getChildren(controller),
          equals(
            const [
              ResizableChild(
                size: ResizableSize.pixels(100),
                child: SizedBox.shrink(),
              ),
            ],
          ),
        );
      });

      test('notifies listeners', () {
        var notified = false;
        controller.addListener(() => notified = true);
        controller.setChildren(const [
          ResizableChild(
            size: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
        ]);
        expect(notified, isTrue);
      });

      test('sets the list of children', () {
        controller.setChildren(const [
          ResizableChild(
            size: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            child: SizedBox.shrink(),
          ),
        ]);

        expect(
          ResizableControllerTestHelper.getChildren(controller).length,
          equals(3),
        );
      });

      test('requests a new layout', () {
        controller.setChildren([
          ResizableChild(child: SizedBox.shrink()),
        ]);

        expect(controller.needsLayout, isTrue);
      });
    });

    group('#adjustChildSize', () {
      setUp(() {
        controller.setChildren(const [
          ResizableChild(
            size: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            child: SizedBox.shrink(),
          ),
        ]);

        fakeAsync((async) {
          manager.setAvailableSpace(200);
          manager.setRenderedSizes([100, 50, 50]);
        });
      });

      group('when increasing the size', () {
        test('increases the size of the target child', () {
          manager.adjustChildSize(index: 1, delta: 10);
          expect(controller.pixels[1], equals(60));
        });

        test('decreases the size of the adjacent child', () {
          manager.adjustChildSize(index: 1, delta: 10);
          expect(controller.pixels[2], equals(40));
        });

        test('notifies listeners', () {
          var notified = false;
          controller.addListener(() => notified = true);
          manager.adjustChildSize(index: 1, delta: 10);
          expect(notified, isTrue);
        });
      });
    });

    group('#setSizes', () {
      setUp(() {
        controller.setChildren(const [
          ResizableChild(
            size: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            child: SizedBox.shrink(),
          ),
        ]);

        fakeAsync((async) {
          manager.setAvailableSpace(200);
          manager.setRenderedSizes([100, 50, 50]);
        });
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

      test('requests a new layout', () {
        controller.setSizes(const [
          ResizableSize.pixels(100),
          ResizableSize.pixels(50),
          ResizableSize.pixels(50),
        ]);

        expect(controller.needsLayout, isTrue);
      });
    });
  });
}

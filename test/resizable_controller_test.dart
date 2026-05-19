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

        manager.setAvailableSpace(300);
        manager.setRenderedSizes([100, 200]);
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

        manager.setAvailableSpace(300);
        manager.setRenderedSizes([100, 200]);
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

          manager.setAvailableSpace(300);
          manager.setRenderedSizes([100, 200]);
        });

        test('does not notify listeners', () {
          var notified = false;
          controller.addListener(() => notified = true);

          manager.setAvailableSpace(300);

          expect(notified, isFalse);
        });
      });

      group('when changing the available space', () {
        group('when only pixel sizes are present', () {
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

            manager.setAvailableSpace(300);
            manager.setRenderedSizes([100, 200]);
          });

          test('adjusts child sizes', () {
            manager.setAvailableSpace(400);
            expect(controller.pixels, equals([150.0, 250.0]));
          });
        });

        group('when an expand child is present', () {
          setUp(() {
            controller.setChildren(const [
              ResizableChild(
                size: ResizableSize.pixels(100),
                child: SizedBox.shrink(),
              ),
              ResizableChild(
                size: ResizableSize.expand(),
                child: SizedBox.shrink(),
              ),
            ]);

            manager.setAvailableSpace(300);
            manager.setRenderedSizes([100, 200]);
          });

          test('only adjusts the expandable child', () {
            manager.setAvailableSpace(400);
            expect(controller.pixels, equals([100.0, 300.0]));
          });
        });

        group('when an expandable is present and has a constraint', () {
          setUp(() {
            controller.setChildren(const [
              ResizableChild(
                size: ResizableSize.pixels(100),
                child: SizedBox.shrink(),
              ),
              ResizableChild(
                size: ResizableSize.expand(max: 225),
                child: SizedBox.shrink(),
              ),
            ]);

            manager.setAvailableSpace(300);
            manager.setRenderedSizes([100, 200]);
          });

          test('adjusts the expandable child to its maximum size', () {
            manager.setAvailableSpace(400);
            expect(controller.pixels.last, equals(225.0));
          });

          test('distributes remaining delta to other children', () {
            manager.setAvailableSpace(400);
            expect(controller.pixels.first, equals(175.0));
          });
        });

        group('when a shrink size is present', () {
          setUp(() {
            controller.setChildren(const [
              ResizableChild(
                size: ResizableSize.pixels(100),
                child: SizedBox.shrink(),
              ),
              ResizableChild(
                size: ResizableSize.shrink(),
                child: SizedBox.shrink(),
              ),
            ]);

            manager.setAvailableSpace(300);
            manager.setRenderedSizes([100, 200]);
          });

          test('adjusts the children equally', () {
            manager.setAvailableSpace(400);
            expect(controller.pixels, equals([150.0, 250.0]));
          });
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

        manager.setAvailableSpace(200);
        manager.setRenderedSizes([100, 50, 50]);
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

        manager.setAvailableSpace(200);
        manager.setRenderedSizes([100, 50, 50]);
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

    group('#hide / #show', () {
      setUp(() {
        controller.setChildren(const [
          ResizableChild(
            size: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            size: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            size: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
        ]);

        manager.setAvailableSpace(300);
        manager.setRenderedSizes([100, 100, 100]);
      });

      test('hide marks the child as hidden and replaces its size with zero',
          () {
        controller.hide(1);

        expect(controller.isHidden(1), isTrue);
        expect(controller.hiddenIndices, equals({1}));
        expect(controller.sizes[1], equals(const ResizableSize.pixels(0)));
        expect(controller.needsLayout, isTrue);
      });

      test('hide notifies listeners', () {
        var notified = false;
        controller.addListener(() => notified = true);

        controller.hide(0);

        expect(notified, isTrue);
      });

      test('hide is a no-op when already hidden', () {
        controller.hide(0);

        var notified = false;
        controller.addListener(() => notified = true);

        controller.hide(0);

        expect(notified, isFalse);
      });

      test('show restores the previously-set size', () {
        controller.hide(0);
        controller.show(0);

        expect(controller.isHidden(0), isFalse);
        expect(controller.hiddenIndices, isEmpty);
        expect(controller.sizes[0], equals(const ResizableSize.pixels(100)));
      });

      test('show is a no-op when the child is visible', () {
        var notified = false;
        controller.addListener(() => notified = true);

        controller.show(0);

        expect(notified, isFalse);
      });

      test('hide throws when index is out of range', () {
        expect(() => controller.hide(-1), throwsRangeError);
        expect(() => controller.hide(3), throwsRangeError);
      });

      test('setSizes while hidden remembers the new size for show()', () {
        controller.hide(1);

        controller.setSizes(const [
          ResizableSize.pixels(50),
          ResizableSize.pixels(120),
          ResizableSize.pixels(50),
        ]);

        // hidden index still zero-sized
        expect(controller.sizes[1], equals(const ResizableSize.pixels(0)));
        expect(controller.isHidden(1), isTrue);

        controller.show(1);
        expect(controller.sizes[1], equals(const ResizableSize.pixels(120)));
      });

      test('setSizes ignores hidden indices when validating totals', () {
        controller.hide(2);

        // Without ignoring index 2, this would exceed available space (300).
        expect(
          () => controller.setSizes(const [
            ResizableSize.pixels(150),
            ResizableSize.pixels(150),
            ResizableSize.pixels(200),
          ]),
          returnsNormally,
        );
      });

      test('setChildren clears hidden state', () {
        controller.hide(0);

        controller.setChildren(const [
          ResizableChild(
            size: ResizableSize.pixels(50),
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            size: ResizableSize.pixels(50),
            child: SizedBox.shrink(),
          ),
        ]);

        expect(controller.hiddenIndices, isEmpty);
      });

      test('setHidden(true) and setHidden(false) match hide/show', () {
        controller.setHidden(0, true);
        expect(controller.isHidden(0), isTrue);

        controller.setHidden(0, false);
        expect(controller.isHidden(0), isFalse);
      });
    });
  });
}

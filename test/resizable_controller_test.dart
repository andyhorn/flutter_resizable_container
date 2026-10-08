import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
        manager.setChildren(const [
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
        manager.setChildren(const [
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
          manager.setChildren(const [
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
            manager.setChildren(const [
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
            manager.setChildren(const [
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
            manager.setChildren(const [
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
            manager.setChildren(const [
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
        const child = SizedBox.shrink();
        const children = [
          ResizableChild(
            size: ResizableSize.pixels(100),
            child: child,
          ),
        ];

        manager.setChildren(children);

        expect(
          ResizableControllerTestHelper.getChildren(controller),
          equals(children),
        );
      });

      test('notifies listeners once', () {
        var notified = 0;
        controller.addListener(() => notified++);
        manager.setChildren(const [
          ResizableChild(
            size: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
        ]);
        expect(notified, equals(1));
      });

      test('sets the list of children', () {
        manager.setChildren(const [
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
        manager.setChildren([
          ResizableChild(child: SizedBox.shrink()),
        ]);

        expect(controller.needsLayout, isTrue);
      });
    });

    group('#setChildren (deprecated)', () {
      test('resets sizes and notifies listeners', () {
        var notified = 0;
        controller.addListener(() => notified++);

        // ignore: deprecated_member_use_from_same_package
        controller.setChildren(const [
          ResizableChild(
            size: ResizableSize.pixels(100),
            child: SizedBox.shrink(),
          ),
          ResizableChild(
            child: SizedBox.shrink(),
          ),
        ]);

        expect(
          ResizableControllerTestHelper.getChildren(controller).length,
          equals(2),
        );
        expect(controller.needsLayout, isTrue);
        expect(notified, equals(1));
      });
    });

    group('#adjustChildSize', () {
      setUp(() {
        manager.setChildren(const [
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

    group('#adjustChildSize with cascadeNegativeDelta', () {
      group('when dragging right (delta > 0)', () {
        test(
          'does not grow the selected child past its max constraint',
          () {
            manager.setChildren(const [
              ResizableChild(
                size: ResizableSize.pixels(50),
                child: SizedBox.shrink(),
              ),
              ResizableChild(
                size: ResizableSize.pixels(60, max: 70),
                child: SizedBox.shrink(),
              ),
              ResizableChild(
                size: ResizableSize.pixels(50, min: 20),
                child: SizedBox.shrink(),
              ),
              ResizableChild(
                size: ResizableSize.pixels(40, min: 20),
                child: SizedBox.shrink(),
              ),
            ]);

            manager.setAvailableSpace(200);
            manager.setRenderedSizes([50, 60, 50, 40]);
            manager.setCascadeNegativeDelta(true);

            // Drag divider after index=1 far to the right. Index 2 can only
            // give up 30 (50 -> 20) and index 3 can give up 20 (40 -> 20),
            // which would naively grow index 1 by 50 -> 110, well past its
            // max of 70. The cascade must clamp at the max.
            manager.adjustChildSize(index: 1, delta: 100);

            expect(controller.pixels[1], lessThanOrEqualTo(70));
            expect(controller.pixels[1], equals(70));
            // total width is preserved
            expect(controller.pixels.reduce((a, b) => a + b), equals(200));
          },
        );

        test(
          'shrinks rightward siblings only by what the selected child can absorb',
          () {
            manager.setChildren(const [
              ResizableChild(
                size: ResizableSize.pixels(50),
                child: SizedBox.shrink(),
              ),
              ResizableChild(
                size: ResizableSize.pixels(60, max: 70),
                child: SizedBox.shrink(),
              ),
              ResizableChild(
                size: ResizableSize.pixels(50, min: 20),
                child: SizedBox.shrink(),
              ),
              ResizableChild(
                size: ResizableSize.pixels(40, min: 20),
                child: SizedBox.shrink(),
              ),
            ]);

            manager.setAvailableSpace(200);
            manager.setRenderedSizes([50, 60, 50, 40]);
            manager.setCascadeNegativeDelta(true);

            manager.adjustChildSize(index: 1, delta: 100);

            // index 1 only had room for +10 (60 -> 70). That 10 must come
            // entirely from the immediate neighbor; the outer sibling stays.
            expect(controller.pixels[2], equals(40));
            expect(controller.pixels[3], equals(40));
          },
        );

        test('does not reverse when the selected child is over its max', () {
          controller.setChildren(const [
            ResizableChild(
              size: ResizableSize.pixels(50),
              child: SizedBox.shrink(),
            ),
            ResizableChild(
              size: ResizableSize.pixels(60, max: 70),
              child: SizedBox.shrink(),
            ),
            ResizableChild(
              size: ResizableSize.pixels(50, min: 20),
              child: SizedBox.shrink(),
            ),
          ]);

          manager.setAvailableSpace(200);
          manager.setRenderedSizes([50, 80, 70]);
          manager.setCascadeNegativeDelta(true);

          manager.adjustChildSize(index: 1, delta: 100);

          expect(controller.pixels, equals([50, 80, 70]));
        });
      });

      group('when dragging left (delta < 0)', () {
        test(
          'does not grow the right sibling past its max constraint',
          () {
            manager.setChildren(const [
              ResizableChild(
                size: ResizableSize.pixels(40, min: 20),
                child: SizedBox.shrink(),
              ),
              ResizableChild(
                size: ResizableSize.pixels(50, min: 20),
                child: SizedBox.shrink(),
              ),
              ResizableChild(
                size: ResizableSize.pixels(60, min: 20),
                child: SizedBox.shrink(),
              ),
              ResizableChild(
                size: ResizableSize.pixels(50, max: 60),
                child: SizedBox.shrink(),
              ),
            ]);

            manager.setAvailableSpace(200);
            manager.setRenderedSizes([40, 50, 60, 50]);
            manager.setCascadeNegativeDelta(true);

            // Drag divider after index=2 to the left. Index 2 is at min 20
            // possible (60 -> 20 = 40 freed), index 1 (50 -> 20 = 30), index
            // 0 (40 -> 20 = 20). Naively, that could grow index 3 by up to
            // 90 to 140 — past its max of 60.
            manager.adjustChildSize(index: 2, delta: -100);

            // Index 3 can only take 10 more (50 -> 60), and that 10 comes
            // from index 2, the child next to the divider.
            expect(controller.pixels, equals([40, 50, 50, 60]));
          },
        );

        test('shrinks the neighbor before its left siblings', () {
          controller.setChildren(const [
            ResizableChild(
              size: ResizableSize.pixels(50),
              child: SizedBox.shrink(),
            ),
            ResizableChild(
              size: ResizableSize.pixels(25, min: 20),
              child: SizedBox.shrink(),
            ),
            ResizableChild(
              size: ResizableSize.pixels(125),
              child: SizedBox.shrink(),
            ),
          ]);

          manager.setAvailableSpace(200);
          manager.setRenderedSizes([50, 25, 125]);
          manager.setCascadeNegativeDelta(true);

          manager.adjustChildSize(index: 1, delta: -20);

          expect(controller.pixels, equals([35, 20, 145]));
        });

        test('applies the neighbor slack when outer siblings are at min', () {
          controller.setChildren(const [
            ResizableChild(
              size: ResizableSize.pixels(20, min: 20),
              child: SizedBox.shrink(),
            ),
            ResizableChild(
              size: ResizableSize.pixels(25, min: 20),
              child: SizedBox.shrink(),
            ),
            ResizableChild(
              size: ResizableSize.pixels(155),
              child: SizedBox.shrink(),
            ),
          ]);

          manager.setAvailableSpace(200);
          manager.setRenderedSizes([20, 25, 155]);
          manager.setCascadeNegativeDelta(true);

          manager.adjustChildSize(index: 1, delta: -20);

          expect(controller.pixels, equals([20, 20, 160]));
        });

        test('does not reverse when the right sibling is over its max', () {
          controller.setChildren(const [
            ResizableChild(
              size: ResizableSize.pixels(60, min: 20),
              child: SizedBox.shrink(),
            ),
            ResizableChild(
              size: ResizableSize.pixels(60, min: 20),
              child: SizedBox.shrink(),
            ),
            ResizableChild(
              size: ResizableSize.pixels(60, max: 70),
              child: SizedBox.shrink(),
            ),
          ]);

          manager.setAvailableSpace(200);
          manager.setRenderedSizes([60, 60, 80]);
          manager.setCascadeNegativeDelta(true);

          manager.adjustChildSize(index: 1, delta: -100);

          expect(controller.pixels, equals([60, 60, 80]));
        });

        test('does not grow a selected child that is below its min', () {
          controller.setChildren(const [
            ResizableChild(
              size: ResizableSize.pixels(60, min: 20),
              child: SizedBox.shrink(),
            ),
            ResizableChild(
              size: ResizableSize.pixels(40, min: 40),
              child: SizedBox.shrink(),
            ),
            ResizableChild(
              size: ResizableSize.pixels(100),
              child: SizedBox.shrink(),
            ),
          ]);

          manager.setAvailableSpace(200);
          manager.setRenderedSizes([70, 30, 100]);
          manager.setCascadeNegativeDelta(true);

          manager.adjustChildSize(index: 1, delta: -20);

          expect(controller.pixels, equals([50, 30, 120]));
        });
      });
    });

    group('#setSizes', () {
      setUp(() {
        manager.setChildren(const [
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

    group('#setSizes float tolerance', () {
      void setUpChildren(int count, double availableSpace) {
        controller.setChildren([
          for (var i = 0; i < count; i++)
            const ResizableChild(child: SizedBox.shrink()),
        ]);
        manager.setAvailableSpace(availableSpace);
      }

      test('accepts 6 even splits of 998 pixels', () {
        setUpChildren(6, 998);
        final size = ResizableSize.pixels(998 / 6);

        expect(
          [for (var i = 0; i < 6; i++) 998 / 6]
              .fold<double>(0, (a, b) => a + b),
          greaterThan(998),
        );
        expect(() => controller.setSizes([for (var i = 0; i < 6; i++) size]),
            returnsNormally);
      });

      test('accepts 7 even splits of 1000 pixels', () {
        setUpChildren(7, 1000);
        final size = ResizableSize.pixels(1000 / 7);

        expect(
          [for (var i = 0; i < 7; i++) 1000 / 7]
              .fold<double>(0, (a, b) => a + b),
          greaterThan(1000),
        );
        expect(() => controller.setSizes([for (var i = 0; i < 7; i++) size]),
            returnsNormally);
      });

      test('accepts 9 even ratio splits', () {
        setUpChildren(9, 900);
        final ratio = ResizableSize.ratio(1 / 9);

        expect(
          [for (var i = 0; i < 9; i++) 1 / 9].fold<double>(0, (a, b) => a + b),
          greaterThan(1.0),
        );
        expect(() => controller.setSizes([for (var i = 0; i < 9; i++) ratio]),
            returnsNormally);
      });

      test('accepts a pixel total just under the tolerance', () {
        setUpChildren(2, 100);

        expect(
          () => controller.setSizes(const [
            ResizableSize.pixels(50 + 5e-7),
            ResizableSize.pixels(50),
          ]),
          returnsNormally,
        );
      });

      test('rejects a pixel total just over the tolerance', () {
        setUpChildren(2, 100);

        expect(
          () => controller.setSizes(const [
            ResizableSize.pixels(50 + 2e-6),
            ResizableSize.pixels(50),
          ]),
          throwsArgumentError,
        );
      });

      test('accepts a ratio total just under the tolerance', () {
        setUpChildren(2, 100);

        expect(
          () => controller.setSizes(const [
            ResizableSize.ratio(0.5 + 5e-7),
            ResizableSize.ratio(0.5),
          ]),
          returnsNormally,
        );
      });

      test('rejects a ratio total just over the tolerance', () {
        setUpChildren(2, 100);

        expect(
          () => controller.setSizes(const [
            ResizableSize.ratio(0.5 + 2e-6),
            ResizableSize.ratio(0.5),
          ]),
          throwsArgumentError,
        );
      });

      test('still rejects pixels that are genuinely over the limit', () {
        setUpChildren(2, 100);

        for (final excess in [1.0, 0.001]) {
          expect(
            () => controller.setSizes([
              ResizableSize.pixels(50 + excess),
              const ResizableSize.pixels(50),
            ]),
            throwsArgumentError,
          );
        }
      });

      test('still rejects a ratio that is genuinely over 1.0', () {
        setUpChildren(2, 100);

        for (final excess in [0.01, 0.001]) {
          expect(
            () => controller.setSizes([
              ResizableSize.ratio(0.5 + excess),
              const ResizableSize.ratio(0.5),
            ]),
            throwsArgumentError,
          );
        }
      });
    });

    group('#hide / #show', () {
      setUp(() {
        manager.setChildren(const [
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
        expect(
          controller.sizes[1],
          equals(const ResizableSize.pixels(0, min: 0, max: 0)),
        );
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
        expect(
          controller.sizes[1],
          equals(const ResizableSize.pixels(0, min: 0, max: 0)),
        );
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

        manager.setChildren(const [
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

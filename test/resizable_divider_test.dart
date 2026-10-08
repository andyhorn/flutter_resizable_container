import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
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

    group('onHoverEnter', () {
      testWidgets('fires when the divider is hovered', (tester) async {
        bool hovered = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                controller: ResizableController(),
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    divider: ResizableDivider(
                      onHoverEnter: () => hovered = true,
                    ),
                    child: SizedBox.expand(),
                  ),
                  const ResizableChild(
                    child: SizedBox.expand(),
                  ),
                ],
              ),
            ),
          ),
        );

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );

        await gesture.addPointer(location: Offset.zero);
        addTearDown(() => gesture.removePointer());

        await tester.pump();
        await gesture.moveTo(
          tester.getCenter(
            find.byType(ResizableContainerDivider),
          ),
        );
        await tester.pumpAndSettle();

        expect(hovered, isTrue);
      });

      testWidgets('Does not fire when hovering over empty padding',
          (tester) async {
        bool hovered = false;

        await tester.binding.setSurfaceSize(const Size(1000, 1000));
        addTearDown(() async => await tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                controller: ResizableController(),
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    divider: ResizableDivider(
                      onHoverEnter: () => hovered = true,
                      length: const ResizableSize.ratio(0.1),
                      crossAxisAlignment: CrossAxisAlignment.start,
                    ),
                    child: SizedBox.expand(),
                  ),
                  const ResizableChild(
                    child: SizedBox.expand(),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );

        // start at bottom right corner of the screen
        await gesture.addPointer(location: const Offset(1000, 1000));
        addTearDown(() => gesture.removePointer());
        await tester.pump();

        await gesture.moveTo(const Offset(500, 1000));
        await tester.pump();

        expect(hovered, isFalse);
      });
    });

    group('onHoverExit', () {
      testWidgets('fires when the divider is un-hovered', (tester) async {
        bool hovered = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                controller: ResizableController(),
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    divider: ResizableDivider(
                      onHoverExit: () => hovered = false,
                    ),
                    child: SizedBox.expand(),
                  ),
                  const ResizableChild(
                    child: SizedBox.expand(),
                  ),
                ],
              ),
            ),
          ),
        );

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );

        await gesture.addPointer(location: Offset.zero);
        addTearDown(() => gesture.removePointer());

        await tester.pump();
        await gesture.moveTo(
          tester.getCenter(
            find.byType(ResizableContainerDivider),
          ),
        );
        await tester.pumpAndSettle();

        await gesture.moveTo(Offset.zero);
        await tester.pumpAndSettle();

        expect(hovered, isFalse);
      });
    });

    group('onTapDown', () {
      testWidgets('fires when the divider is tapped down', (tester) async {
        bool dividerTappedDown = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                controller: ResizableController(),
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    divider: ResizableDivider(
                      onTapDown: () => dividerTappedDown = true,
                    ),
                    child: SizedBox.expand(),
                  ),
                  const ResizableChild(
                    child: SizedBox.expand(),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final dividerFinder = find.byType(ResizableContainerDivider);
        expect(dividerFinder, findsOneWidget);

        // Simulate tap on the divider
        await tester.tap(dividerFinder, kind: PointerDeviceKind.touch);
        await tester.pump();

        expect(dividerTappedDown, isTrue);
      });

      testWidgets('does not fire when tapping outside the divider',
          (tester) async {
        bool dividerTappedDown = false;
        bool otherTappedDown = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  // Outer GestureDetector to simulate tapping outside the divider
                  GestureDetector(
                    onTapDown: (_) => otherTappedDown = true,
                    child: Container(
                      color: Colors.transparent,
                      width: 300,
                      height: 300,
                    ),
                  ),
                  // ResizableContainer with ResizableDivider
                  ResizableContainer(
                    controller: ResizableController(),
                    direction: Axis.horizontal,
                    children: [
                      ResizableChild(
                        divider: ResizableDivider(
                          onTapDown: () => dividerTappedDown = true,
                        ),
                        child: SizedBox.expand(),
                      ),
                      const ResizableChild(
                        child: SizedBox.expand(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap outside the divider
        await tester.tapAt(const Offset(10, 10), kind: PointerDeviceKind.touch);
        await tester.pump();

        expect(otherTappedDown, isTrue,
            reason: 'Outer GestureDetector should detect the tap.');
        expect(dividerTappedDown, isFalse,
            reason:
                'ResizableDivider onTapDown should not be triggered when tapping outside.');
      });
    });

    group('enabled', () {
      testWidgets('suppresses drag-driven resizing when false', (tester) async {
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.binding.setSurfaceSize(const Size(400, 100));
        addTearDown(() async => await tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                controller: controller,
                direction: Axis.horizontal,
                children: const [
                  ResizableChild(
                    size: ResizableSize.ratio(0.5),
                    divider: ResizableDivider(enabled: false),
                    child: SizedBox.expand(),
                  ),
                  ResizableChild(
                    size: ResizableSize.ratio(0.5),
                    child: SizedBox.expand(),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final beforeSizes = List<double>.of(controller.pixels);
        final divider = find.byType(ResizableContainerDivider);

        await tester.drag(divider, const Offset(50, 0));
        await tester.pumpAndSettle();

        expect(controller.pixels, beforeSizes);
      });

      testWidgets('suppresses tap, hover, and drag callbacks when false',
          (tester) async {
        var hoverEnter = false;
        var hoverExit = false;
        var tappedDown = false;
        var tappedUp = false;
        var dragStarted = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                controller: ResizableController(),
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    divider: ResizableDivider(
                      enabled: false,
                      onHoverEnter: () => hoverEnter = true,
                      onHoverExit: () => hoverExit = true,
                      onTapDown: () => tappedDown = true,
                      onTapUp: () => tappedUp = true,
                      onDragStart: () => dragStarted = true,
                    ),
                    child: const SizedBox.expand(),
                  ),
                  const ResizableChild(child: SizedBox.expand()),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final divider = find.byType(ResizableContainerDivider);

        final gesture =
            await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(() => gesture.removePointer());
        await tester.pump();
        await gesture.moveTo(tester.getCenter(divider));
        await tester.pumpAndSettle();
        await gesture.moveTo(Offset.zero);
        await tester.pumpAndSettle();

        await tester.tap(divider, kind: PointerDeviceKind.touch);
        await tester.pumpAndSettle();

        await tester.drag(divider, const Offset(40, 0));
        await tester.pumpAndSettle();

        expect(hoverEnter, isFalse);
        expect(hoverExit, isFalse);
        expect(tappedDown, isFalse);
        expect(tappedUp, isFalse);
        expect(dragStarted, isFalse);
      });
    });

    group('onTapUp', () {
      testWidgets('fires when the divider tap is released', (tester) async {
        bool tappedUp = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                controller: ResizableController(),
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    divider: ResizableDivider(
                      onTapUp: () => tappedUp = true,
                    ),
                    child: SizedBox.expand(),
                  ),
                  const ResizableChild(
                    child: SizedBox.expand(),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final dividerFinder = find.byType(ResizableContainerDivider);
        expect(dividerFinder, findsOneWidget);

        // Simulate tap down and tap up gesture
        final gesture = await tester.startGesture(
            tester.getCenter(dividerFinder),
            kind: PointerDeviceKind.touch);
        await tester.pump();
        await gesture.up();
        await tester.pump();

        expect(tappedUp, isTrue);
      });

      testWidgets('does not fire when tap is canceled', (tester) async {
        bool tappedUp = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                controller: ResizableController(),
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    divider: ResizableDivider(
                      onTapUp: () => tappedUp = true,
                    ),
                    child: SizedBox.expand(),
                  ),
                  const ResizableChild(
                    child: SizedBox.expand(),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final dividerFinder = find.byType(ResizableContainerDivider);
        expect(dividerFinder, findsOneWidget);

        // Simulate tap gesture and cancel it
        final gesture = await tester.startGesture(
            tester.getCenter(dividerFinder),
            kind: PointerDeviceKind.touch);
        await tester.pump();
        await gesture.cancel();
        await tester.pump();

        expect(tappedUp, isFalse);
      });
    });

    group('when disabled mid-hover', () {
      testWidgets('fires onHoverExit on the config that saw the hover',
          (tester) async {
        var oldExits = 0;
        var newExits = 0;

        Widget build(
            {required bool enabled, required ResizableDivider config}) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 40,
                  height: 200,
                  child: ResizableContainerDivider(
                    direction: Axis.horizontal,
                    config: config,
                    enabled: enabled,
                    onResizeUpdate: (_) {},
                  ),
                ),
              ),
            ),
          );
        }

        final oldConfig = ResizableDivider(
          thickness: 10,
          onHoverExit: () => oldExits++,
        );
        final newConfig = ResizableDivider(
          thickness: 10,
          onHoverExit: () => newExits++,
        );

        await tester.pumpWidget(build(enabled: true, config: oldConfig));

        final gesture =
            await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();
        await gesture.moveTo(
          tester.getCenter(find.byType(ResizableContainerDivider)),
        );
        await tester.pump();

        await tester.pumpWidget(build(enabled: false, config: newConfig));
        await tester.pump();

        expect(oldExits, 1);
        expect(newExits, 0);
      });
    });

    group('gesture capture', () {
      Future<void> pumpScrollable(
        WidgetTester tester, {
        required Axis containerDirection,
        required ScrollController scrollController,
        required ResizableController controller,
        ResizableDivider divider = const ResizableDivider(),
      }) async {
        final isHorizontal = containerDirection == Axis.horizontal;
        final container = SizedBox(
          width: isHorizontal ? 400 : 100,
          height: isHorizontal ? 100 : 400,
          child: ResizableContainer(
            controller: controller,
            direction: containerDirection,
            children: [
              ResizableChild(
                size: const ResizableSize.ratio(0.5),
                divider: divider,
                child: const SizedBox.expand(),
              ),
              const ResizableChild(
                size: ResizableSize.ratio(0.5),
                child: SizedBox.expand(),
              ),
            ],
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView(
                controller: scrollController,
                scrollDirection: isHorizontal ? Axis.vertical : Axis.horizontal,
                children: [container, SizedBox(width: 2000, height: 2000)],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      late ScrollController scrollController;
      late ResizableController controller;

      setUp(() {
        scrollController = ScrollController();
        controller = ResizableController();
      });

      tearDown(() {
        scrollController.dispose();
        controller.dispose();
      });

      testWidgets(
        'a vertical drag on a horizontal container divider scrolls the list',
        (tester) async {
          await pumpScrollable(
            tester,
            containerDirection: Axis.horizontal,
            scrollController: scrollController,
            controller: controller,
          );
          final before = List<double>.of(controller.pixels);

          await tester.drag(
            find.byType(ResizableContainerDivider),
            const Offset(0, -50),
          );
          await tester.pumpAndSettle();

          expect(scrollController.offset, greaterThan(0));
          expect(controller.pixels, before);
        },
      );

      testWidgets(
        'a horizontal drag on a vertical container divider scrolls the list',
        (tester) async {
          await pumpScrollable(
            tester,
            containerDirection: Axis.vertical,
            scrollController: scrollController,
            controller: controller,
          );
          final before = List<double>.of(controller.pixels);

          await tester.drag(
            find.byType(ResizableContainerDivider),
            const Offset(-50, 0),
          );
          await tester.pumpAndSettle();

          expect(scrollController.offset, greaterThan(0));
          expect(controller.pixels, before);
        },
      );

      Future<ScrollController> pumpSameAxisScrollable(
        WidgetTester tester, {
        bool resizable = true,
        ResizableDivider divider = const ResizableDivider(),
      }) async {
        final horizontalScroll = ScrollController();
        addTearDown(horizontalScroll.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                controller: horizontalScroll,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 1200,
                  height: 100,
                  child: ResizableContainer(
                    controller: controller,
                    direction: Axis.horizontal,
                    resizable: resizable,
                    children: [
                      ResizableChild(
                        size: const ResizableSize.ratio(0.5),
                        divider: divider,
                        child: const SizedBox.expand(),
                      ),
                      const ResizableChild(
                        size: ResizableSize.ratio(0.5),
                        child: SizedBox.expand(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return horizontalScroll;
      }

      testWidgets(
        'a main-axis drag on a disabled divider scrolls a same-axis '
        'scrollable',
        (tester) async {
          final horizontalScroll = await pumpSameAxisScrollable(
            tester,
            divider: const ResizableDivider(enabled: false),
          );
          final before = List<double>.of(controller.pixels);

          await tester.drag(
            find.byType(ResizableContainerDivider),
            const Offset(-50, 0),
          );
          await tester.pumpAndSettle();

          expect(horizontalScroll.offset, greaterThan(0));
          expect(controller.pixels, before);
        },
      );

      testWidgets(
        'a main-axis drag on a non-resizable container divider scrolls a '
        'same-axis scrollable',
        (tester) async {
          final horizontalScroll = await pumpSameAxisScrollable(
            tester,
            resizable: false,
          );
          final before = List<double>.of(controller.pixels);

          await tester.drag(
            find.byType(ResizableContainerDivider),
            const Offset(-50, 0),
          );
          await tester.pumpAndSettle();

          expect(horizontalScroll.offset, greaterThan(0));
          expect(controller.pixels, before);
        },
      );

      testWidgets(
        'an enabled divider still resizes on a main-axis drag and fires '
        'onDragStart and onDragEnd once',
        (tester) async {
          var dragStarts = 0;
          var dragEnds = 0;

          await pumpScrollable(
            tester,
            containerDirection: Axis.horizontal,
            scrollController: scrollController,
            controller: controller,
            divider: ResizableDivider(
              onDragStart: () => dragStarts++,
              onDragEnd: () => dragEnds++,
            ),
          );
          final before = List<double>.of(controller.pixels);

          await tester.drag(
            find.byType(ResizableContainerDivider),
            const Offset(50, 0),
          );
          await tester.pumpAndSettle();

          expect(controller.pixels.first, greaterThan(before.first));
          expect(scrollController.offset, 0);
          expect(dragStarts, 1);
          expect(dragEnds, 1);
        },
      );
    });

    group('props', () {
      test('includes onDragStart', () {
        void onDragStart() {}

        expect(
          ResizableDivider(onDragStart: onDragStart),
          ResizableDivider(onDragStart: onDragStart),
        );
        expect(
          ResizableDivider(onDragStart: onDragStart),
          isNot(const ResizableDivider()),
        );
      });

      test('includes onDragEnd', () {
        void onDragEnd() {}

        expect(
          ResizableDivider(onDragEnd: onDragEnd),
          ResizableDivider(onDragEnd: onDragEnd),
        );
        expect(
          ResizableDivider(onDragEnd: onDragEnd),
          isNot(const ResizableDivider()),
        );
      });
    });
  });
}

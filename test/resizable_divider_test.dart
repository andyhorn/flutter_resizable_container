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
                divider: ResizableDivider(
                  onHoverEnter: () => hovered = true,
                ),
                children: const [
                  ResizableChild(
                    child: SizedBox.expand(),
                  ),
                  ResizableChild(
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
                divider: ResizableDivider(
                  onHoverEnter: () => hovered = true,
                  length: const ResizableSize.ratio(0.1),
                  crossAxisAlignment: CrossAxisAlignment.start,
                ),
                children: const [
                  ResizableChild(
                    child: SizedBox.expand(),
                  ),
                  ResizableChild(
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
                divider: ResizableDivider(
                  onHoverExit: () => hovered = false,
                ),
                children: const [
                  ResizableChild(
                    child: SizedBox.expand(),
                  ),
                  ResizableChild(
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
                divider: ResizableDivider(
                  onTapDown: () => dividerTappedDown = true,
                ),
                children: const [
                  ResizableChild(
                    child: SizedBox.expand(),
                  ),
                  ResizableChild(
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
                    divider: ResizableDivider(
                      onTapDown: () => dividerTappedDown = true,
                    ),
                    children: const [
                      ResizableChild(
                        child: SizedBox.expand(),
                      ),
                      ResizableChild(
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

    group('onTapUp', () {
      testWidgets('fires when the divider tap is released', (tester) async {
        bool tappedUp = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                controller: ResizableController(),
                direction: Axis.horizontal,
                divider: ResizableDivider(
                  onTapUp: () => tappedUp = true,
                ),
                children: const [
                  ResizableChild(
                    child: SizedBox.expand(),
                  ),
                  ResizableChild(
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
                divider: ResizableDivider(
                  onTapUp: () => tappedUp = true,
                ),
                children: const [
                  ResizableChild(
                    child: SizedBox.expand(),
                  ),
                  ResizableChild(
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
          kind: PointerDeviceKind.touch,
        );

        await tester.pump();
        await gesture.cancel();
        await tester.pump();

        expect(tappedUp, isFalse);
      });
    });
  });
}

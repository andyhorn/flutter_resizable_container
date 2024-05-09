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

    group('onHoverEnter', () {
      testWidgets('fires when the divider is hovered', (tester) async {
        bool hovered = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                controller: ResizableController(
                  data: const [
                    ResizableChild(),
                    ResizableChild(),
                  ],
                ),
                direction: Axis.horizontal,
                divider: ResizableDivider(
                  onHoverEnter: () => hovered = true,
                ),
                children: const [
                  SizedBox.expand(),
                  SizedBox.expand(),
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
    });

    group('onHoverExit', () {
      testWidgets('fires when the divider is un-hovered', (tester) async {
        bool hovered = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                controller: ResizableController(
                  data: const [
                    ResizableChild(),
                    ResizableChild(),
                  ],
                ),
                direction: Axis.horizontal,
                divider: ResizableDivider(
                  onHoverExit: () => hovered = false,
                ),
                children: const [
                  SizedBox.expand(),
                  SizedBox.expand(),
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
  });
}

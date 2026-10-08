import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('unbounded constraints', () {
    const children = [
      ResizableChild(child: SizedBox.expand()),
      ResizableChild(child: SizedBox.expand()),
    ];

    Future<FlutterError> pumpAndCapture(
      WidgetTester tester,
      Widget child,
    ) async {
      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: child),
      );

      expect(errors, isNotEmpty);
      final first = errors.first.exception;
      expect(first, isA<FlutterError>());
      return first as FlutterError;
    }

    testWidgets('explains an unbounded width inside a Row', (tester) async {
      final error = await pumpAndCapture(
        tester,
        const SizedBox(
          height: 300,
          child: Row(
            children: [
              ResizableContainer(
                direction: Axis.horizontal,
                children: children,
              ),
            ],
          ),
        ),
      );

      final message = error.toString();
      expect(message, contains('ResizableContainer'));
      expect(message, contains('unbounded width'));
      expect(message, isNot(contains('unbounded height')));
      expect(message, contains('Expanded'));
    });

    testWidgets('explains an unbounded height inside a Column', (tester) async {
      final error = await pumpAndCapture(
        tester,
        const SizedBox(
          width: 300,
          child: Column(
            children: [
              ResizableContainer(
                direction: Axis.vertical,
                children: children,
              ),
            ],
          ),
        ),
      );

      final message = error.toString();
      expect(message, contains('ResizableContainer'));
      expect(message, contains('unbounded height'));
      expect(message, isNot(contains('unbounded width')));
      expect(message, contains('Expanded'));
    });

    testWidgets(
      'explains an unbounded cross axis for a horizontal container',
      (tester) async {
        final error = await pumpAndCapture(
          tester,
          const SizedBox(
            width: 300,
            child: Column(
              children: [
                ResizableContainer(
                  direction: Axis.horizontal,
                  children: children,
                ),
              ],
            ),
          ),
        );

        final message = error.toString();
        expect(message, contains('ResizableContainer'));
        expect(message, contains('unbounded height'));
        expect(message, isNot(contains('unbounded width')));
      },
    );
  });
}

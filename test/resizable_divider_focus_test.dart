import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_divider_handle.dart';
import 'package:flutter_test/flutter_test.dart';

const _dividerLabel = 'ResizableDividerHandle';

bool _dividerHasFocus() {
  return FocusManager.instance.primaryFocus?.debugLabel == _dividerLabel;
}

Widget _harness(FocusNode fieldNode) {
  return MaterialApp(
    home: Scaffold(
      body: ResizableContainer(
        direction: Axis.horizontal,
        children: [
          ResizableChild(child: TextField(focusNode: fieldNode)),
          const ResizableChild(child: SizedBox()),
        ],
      ),
    ),
  );
}

Future<void> _tap(WidgetTester tester, PointerDeviceKind kind) async {
  final center = tester.getCenter(find.byType(ResizableDividerHandle));
  final gesture = await tester.startGesture(center, kind: kind);
  await gesture.up();
  await tester.pump();
}

Future<void> _drag(WidgetTester tester, PointerDeviceKind kind) async {
  final center = tester.getCenter(find.byType(ResizableDividerHandle));
  final gesture = await tester.startGesture(center, kind: kind);
  await gesture.moveBy(const Offset(20, 0));
  await gesture.up();
  await tester.pump();
}

void main() {
  late FocusNode fieldNode;

  setUp(() => fieldNode = FocusNode());
  tearDown(() => fieldNode.dispose());

  Future<void> pumpWithFocusedField(WidgetTester tester) async {
    await tester.pumpWidget(_harness(fieldNode));
    await tester.pumpAndSettle();
    fieldNode.requestFocus();
    await tester.pump();
    expect(fieldNode.hasPrimaryFocus, isTrue);
  }

  group('mouse', () {
    testWidgets('tap focuses the divider', (tester) async {
      await pumpWithFocusedField(tester);

      await _tap(tester, PointerDeviceKind.mouse);

      expect(_dividerHasFocus(), isTrue);
    });

    testWidgets('drag focuses the divider', (tester) async {
      await pumpWithFocusedField(tester);

      await _drag(tester, PointerDeviceKind.mouse);

      expect(_dividerHasFocus(), isTrue);
    });
  });

  group('touch', () {
    testWidgets('tap does not take focus from a pane text field',
        (tester) async {
      await pumpWithFocusedField(tester);

      await _tap(tester, PointerDeviceKind.touch);

      expect(fieldNode.hasPrimaryFocus, isTrue);
      expect(_dividerHasFocus(), isFalse);
    });

    testWidgets('drag does not take focus from a pane text field',
        (tester) async {
      await pumpWithFocusedField(tester);

      await _drag(tester, PointerDeviceKind.touch);

      expect(fieldNode.hasPrimaryFocus, isTrue);
      expect(_dividerHasFocus(), isFalse);
    });
  });
}

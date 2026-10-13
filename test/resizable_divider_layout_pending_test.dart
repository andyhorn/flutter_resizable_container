import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_divider_handle.dart';
import 'package:flutter_test/flutter_test.dart';

const _label = 'Resize panes';

Widget _harness(ResizableController controller) {
  return MaterialApp(
    home: Scaffold(
      body: ResizableContainer(
        controller: controller,
        direction: Axis.horizontal,
        children: const [
          ResizableChild(
            divider: ResizableDivider(semanticLabel: _label),
            child: SizedBox(),
          ),
          ResizableChild(child: SizedBox()),
        ],
      ),
    ),
  );
}

void main() {
  late ResizableController controller;

  setUp(() {
    controller = ResizableController();
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });

  tearDown(() {
    controller.dispose();
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  Future<void> settleThenInvalidateLayout(WidgetTester tester) async {
    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    final divider = find.byType(ResizableDividerHandle);
    await tester.tapAt(
      tester.getCenter(divider),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();

    controller.setSizes(const [
      ResizableSize.pixels(100),
      ResizableSize.expand(),
    ]);
    expect(controller.needsLayout, isTrue);
  }

  testWidgets('arrow keys do not resize while a layout is pending',
      (tester) async {
    await settleThenInvalidateLayout(tester);
    final before = controller.pixels.toList();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);

    expect(controller.pixels, before);
  });

  testWidgets('semantic increase does not resize while a layout is pending',
      (tester) async {
    final handle = tester.ensureSemantics();
    await settleThenInvalidateLayout(tester);
    final before = controller.pixels.toList();

    tester.semantics.increase(find.semantics.byLabel(_label));

    expect(controller.pixels, before);
    handle.dispose();
  });
}

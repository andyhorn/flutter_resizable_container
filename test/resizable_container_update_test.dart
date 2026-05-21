import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness({
  required ResizableController controller,
  required ResizableDivider divider,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 600,
        height: 400,
        child: ResizableContainer(
          controller: controller,
          direction: Axis.horizontal,
          children: [
            ResizableChild(
              size: const ResizableSize.pixels(200),
              divider: divider,
              child: const ColoredBox(color: Color(0xFF0000FF)),
            ),
            const ResizableChild(
              child: ColoredBox(color: Color(0xFFFF0000)),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  group('ResizableContainer non-structural rebuild', () {
    testWidgets('preserves hidden state when only divider config changes',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      final controller = ResizableController();

      await tester.pumpWidget(
        _harness(
          controller: controller,
          divider: const ResizableDivider(color: Color(0xFF111111)),
        ),
      );
      await tester.pumpAndSettle();

      controller.hide(0);
      await tester.pumpAndSettle();
      expect(controller.isHidden(0), isTrue);

      await tester.pumpWidget(
        _harness(
          controller: controller,
          divider: const ResizableDivider(color: Color(0xFF222222)),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        controller.isHidden(0),
        isTrue,
        reason: 'hidden state should survive a divider-only rebuild',
      );
    });

    testWidgets(
        'preserves saved hidden size when only the child widget instance '
        'changes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 400));
      final controller = ResizableController();

      Widget build(String label) => MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1000,
                height: 400,
                child: ResizableContainer(
                  controller: controller,
                  direction: Axis.horizontal,
                  children: [
                    const ResizableChild(
                      size: ResizableSize.pixels(300),
                      child: ColoredBox(color: Color(0xFF0000FF)),
                    ),
                    ResizableChild(
                      child: Text(label, key: const Key('label')),
                    ),
                  ],
                ),
              ),
            ),
          );

      await tester.pumpWidget(build('first'));
      await tester.pumpAndSettle();

      controller.hide(0);
      await tester.pumpAndSettle();
      expect(controller.isHidden(0), isTrue);

      await tester.pumpWidget(build('second'));
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
      expect(
        controller.isHidden(0),
        isTrue,
        reason: 'hidden state should survive a child-only rebuild',
      );

      controller.show(0);
      await tester.pumpAndSettle();
      expect(
        controller.pixels[0],
        closeTo(300, 1),
        reason: 'saved size from before the rebuild should be restored',
      );
    });

    testWidgets('still resets state when the number of children changes',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      final controller = ResizableController();

      Widget build(int count) => MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 400,
                child: ResizableContainer(
                  controller: controller,
                  direction: Axis.horizontal,
                  children: [
                    for (var i = 0; i < count; i++)
                      ResizableChild(
                        child: ColoredBox(color: Color(0xFF000000 + i * 100)),
                      ),
                  ],
                ),
              ),
            ),
          );

      await tester.pumpWidget(build(2));
      await tester.pumpAndSettle();

      controller.hide(0);
      await tester.pumpAndSettle();

      await tester.pumpWidget(build(3));
      await tester.pumpAndSettle();

      expect(controller.hiddenIndices, isEmpty,
          reason: 'structural change should reset hidden state');
      expect(controller.pixels.length, equals(3));
    });
  });
}

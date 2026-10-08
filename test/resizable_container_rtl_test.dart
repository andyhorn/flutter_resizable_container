import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_test/flutter_test.dart';

import 'remount_test_helpers.dart';

void main() {
  group(ResizableContainer, () {
    group('rtl', () {
      void expectChildAtRightEdge(WidgetTester tester) {
        final container = find.byType(ResizableContainer);
        expect(
          tester.getTopRight(find.byKey(const ValueKey('A'))).dx,
          tester.getTopRight(container).dx,
        );
      }

      testWidgets('places child 0 at the right edge on every frame',
          (tester) async {
        await useSurface(tester, const Size(600, 400));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildHarness(
            controller: controller,
            children: buildChildren({}),
            textDirection: TextDirection.rtl,
            hideAnimation: hideAnimation,
          ),
        );
        expectChildAtRightEdge(tester);
        await tester.pump();
        expectChildAtRightEdge(tester);

        controller.setSizes(const [
          ResizableSize.pixels(100),
          ResizableSize.pixels(200),
          ResizableSize.expand(),
        ]);
        await tester.pump();
        expectChildAtRightEdge(tester);
        await tester.pump();
        expectChildAtRightEdge(tester);

        controller.hide(2);
        await tester.pump();
        expectChildAtRightEdge(tester);
        await tester.pump(const Duration(milliseconds: 100));
        expectChildAtRightEdge(tester);
        await tester.pumpAndSettle();
        expectChildAtRightEdge(tester);

        controller.show(2);
        await tester.pump();
        expectChildAtRightEdge(tester);
        await tester.pumpAndSettle();
        expectChildAtRightEdge(tester);
      });

      testWidgets('places child 0 at the right edge after an instant hide',
          (tester) async {
        await useSurface(tester, const Size(600, 400));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildHarness(
            controller: controller,
            children: buildChildren({}),
            textDirection: TextDirection.rtl,
          ),
        );
        await tester.pumpAndSettle();

        controller.hide(1);
        await tester.pump();
        expectChildAtRightEdge(tester);
        await tester.pump();
        expectChildAtRightEdge(tester);

        controller.show(1);
        await tester.pump();
        expectChildAtRightEdge(tester);
        await tester.pump();
        expectChildAtRightEdge(tester);
      });
    });
  });
}

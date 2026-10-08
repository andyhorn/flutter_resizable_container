import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'remount_test_helpers.dart';

void main() {
  group(ResizableContainer, () {
    Finder dividers() => find.byType(ResizableContainerDivider);

    group('animation lifecycle', () {
      testWidgets('hide followed by setSizes without a pump settles at sizes',
          (tester) async {
        await useSurface(tester, const Size(600, 400));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildHarness(
            controller: controller,
            children: buildChildren({}),
            hideAnimation: hideAnimation,
          ),
        );
        await tester.pumpAndSettle();

        controller.hide(1);
        controller.setSizes(const [
          ResizableSize.pixels(100),
          ResizableSize.pixels(200),
          ResizableSize.expand(),
        ]);
        await tester.pumpAndSettle();

        expect(tester.getSize(find.byKey(const ValueKey('A'))).width, 100);
        expect(tester.getSize(find.byKey(const ValueKey('B'))).width, 0);
        expect(tester.getSize(find.byKey(const ValueKey('C'))).width, 500);
        expect(tester.takeException(), isNull);
      });

      testWidgets('a single pump after an animated hide throws nothing',
          (tester) async {
        await useSurface(tester, const Size(600, 400));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildHarness(
            controller: controller,
            children: buildChildren({}),
            hideAnimation: hideAnimation,
          ),
        );
        await tester.pumpAndSettle();

        controller.hide(1);
        await tester.pump();

        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
      });

      testWidgets('a direction change mid-animation cancels it',
          (tester) async {
        await useSurface(tester, const Size(600, 400));
        final controller = ResizableController();
        addTearDown(controller.dispose);
        final children = buildChildren({});

        await tester.pumpWidget(
          buildHarness(
            controller: controller,
            children: children,
            hideAnimation: hideAnimation,
          ),
        );
        await tester.pumpAndSettle();

        controller.hide(1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.pumpWidget(
          buildHarness(
            controller: controller,
            children: children,
            direction: Axis.vertical,
            hideAnimation: hideAnimation,
          ),
        );
        await tester.pump();
        expect(tester.hasRunningAnimations, isFalse);
        await tester.pumpAndSettle();

        final a = tester.getSize(find.byKey(const ValueKey('A'))).height;
        final b = tester.getSize(find.byKey(const ValueKey('B'))).height;
        final c = tester.getSize(find.byKey(const ValueKey('C'))).height;
        expect(b, 0);
        expect(a + c, closeTo(tester.getSize(find.byType(Scaffold)).height, 1));
        expect(tester.takeException(), isNull);
      });

      testWidgets('a controller swap leaves the new controller untouched',
          (tester) async {
        await useSurface(tester, const Size(600, 400));
        final first = ResizableController();
        final second = ResizableController();
        addTearDown(second.dispose);
        final children = buildChildren({});

        await tester.pumpWidget(
          buildHarness(controller: first, children: children),
        );
        await tester.pump();
        await tester.pumpWidget(
          buildHarness(controller: second, children: children),
        );
        first.dispose();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(second.pixels, [150, 150, 296]);
      });

      testWidgets('resizable: false disables dividers on the first frame',
          (tester) async {
        await useSurface(tester, const Size(600, 400));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                controller: controller,
                direction: Axis.horizontal,
                resizable: false,
                children: buildChildren({}),
              ),
            ),
          ),
        );

        for (var i = 0; i < 2; i++) {
          final divider =
              tester.widget<ResizableContainerDivider>(dividers().at(i));
          expect(divider.enabled, isFalse);
        }
      });

      testWidgets('a structural change while hidden does not animate',
          (tester) async {
        await useSurface(tester, const Size(600, 400));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildHarness(
            controller: controller,
            children: buildChildren({}),
            hideAnimation: hideAnimation,
          ),
        );
        await tester.pumpAndSettle();

        controller.hide(1);
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          buildHarness(
            controller: controller,
            children: buildChildren({}, names: const ['A', 'B', 'C', 'D']),
            hideAnimation: hideAnimation,
          ),
        );
        await tester.pump();

        expect(tester.hasRunningAnimations, isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
      });
    });
  });
}

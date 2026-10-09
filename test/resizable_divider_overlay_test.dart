import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_resizable_container/src/resizable_divider_overlay.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness({
  required Axis direction,
  ResizableController? controller,
  ResizableHideAnimation? hideAnimation,
  TextDirection textDirection = TextDirection.ltr,
  int count = 3,
}) {
  return MaterialApp(
    home: Directionality(
      textDirection: textDirection,
      child: Scaffold(
        body: ResizableContainer(
          direction: direction,
          controller: controller,
          hideAnimation: hideAnimation,
          children: [
            for (var i = 0; i < count; i++)
              ResizableChild(
                size: const ResizableSize.expand(),
                divider: const ResizableDivider(thickness: 4, padding: 6),
                child: SizedBox.expand(key: Key('pane$i')),
              ),
          ],
        ),
      ),
    ),
  );
}

Rect _rect(WidgetTester tester, Finder finder) {
  return tester.getRect(finder);
}

// The divider targets are translucent, so hitTestable() is unreliable for them.
bool _isHit(WidgetTester tester, Finder divider) {
  final region = tester.renderObject(
    find.descendant(of: divider, matching: find.byType(MouseRegion)),
  );
  final result = tester.hitTestOnBinding(tester.getCenter(divider));
  return result.path.any((entry) => identical(entry.target, region));
}

void _expectDividersBetweenPanes(
  WidgetTester tester, {
  required Axis direction,
  required int count,
  TextDirection textDirection = TextDirection.ltr,
}) {
  final dividers = find.byType(ResizableContainerDivider);
  expect(dividers, findsNWidgets(count - 1));

  for (var i = 0; i < count - 1; i++) {
    final before = _rect(tester, find.byKey(Key('pane$i')));
    final after = _rect(tester, find.byKey(Key('pane${i + 1}')));
    final divider = _rect(tester, dividers.at(i));

    switch ((direction, textDirection)) {
      case (Axis.horizontal, TextDirection.ltr):
        expect(divider.left, moreOrLessEquals(before.right));
        expect(divider.right, moreOrLessEquals(after.left));
      case (Axis.horizontal, TextDirection.rtl):
        expect(divider.right, moreOrLessEquals(before.left));
        expect(divider.left, moreOrLessEquals(after.right));
      case (Axis.vertical, _):
        expect(divider.top, moreOrLessEquals(before.bottom));
        expect(divider.bottom, moreOrLessEquals(after.top));
    }
  }
}

void main() {
  group(ResizableDividerOverlay, () {
    group('placement', () {
      for (final direction in Axis.values) {
        testWidgets('sits in the divider slot for $direction', (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(_harness(direction: direction));
          await tester.pumpAndSettle();

          _expectDividersBetweenPanes(tester, direction: direction, count: 3);
        });
      }

      testWidgets('mirrors under RTL', (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _harness(
            direction: Axis.horizontal,
            textDirection: TextDirection.rtl,
          ),
        );
        await tester.pumpAndSettle();

        _expectDividersBetweenPanes(
          tester,
          direction: Axis.horizontal,
          count: 3,
          textDirection: TextDirection.rtl,
        );
      });

      testWidgets('follows the panes after a drag', (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_harness(direction: Axis.horizontal));
        await tester.pumpAndSettle();

        await tester.drag(
          find.byType(ResizableContainerDivider).first,
          const Offset(50, 0),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        _expectDividersBetweenPanes(
          tester,
          direction: Axis.horizontal,
          count: 3,
        );
      });
    });

    group('phases', () {
      testWidgets('ignores pointers while a layout pass is pending',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _harness(direction: Axis.horizontal, controller: controller),
        );

        final overlay = find.ancestor(
          of: find.byType(ResizableDividerOverlay),
          matching: find.byType(IgnorePointer),
        );
        expect(tester.widget<IgnorePointer>(overlay.first).ignoring, isTrue);

        await tester.pumpAndSettle();
        expect(tester.widget<IgnorePointer>(overlay.first).ignoring, isFalse);
      });

      testWidgets('keeps the same divider state across a layout pass',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _harness(direction: Axis.horizontal, controller: controller),
        );
        await tester.pumpAndSettle();
        final before =
            tester.state(find.byType(ResizableContainerDivider).first);

        controller.setSizes(const [
          ResizableSize.pixels(100),
          ResizableSize.expand(),
          ResizableSize.expand(),
        ]);
        await tester.pumpAndSettle();

        expect(
          tester.state(find.byType(ResizableContainerDivider).first),
          same(before),
        );
      });

      testWidgets('tracks the panes while a hide animation runs',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _harness(
            direction: Axis.horizontal,
            controller: controller,
            hideAnimation: const ResizableHideAnimation(),
          ),
        );
        await tester.pumpAndSettle();

        controller.hide(1);
        await tester.pump();
        await tester.pump();

        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 40));
          final dividers = find.byType(ResizableContainerDivider);
          expect(dividers, findsNWidgets(2));
          expect(
            _rect(tester, dividers.first).left,
            moreOrLessEquals(
                _rect(tester, find.byKey(const Key('pane0'))).right),
          );
          expect(
            _rect(tester, dividers.last).right,
            moreOrLessEquals(
                _rect(tester, find.byKey(const Key('pane2'))).left),
          );
        }
      });

      testWidgets('keeps hidden dividers mounted without an interactive target',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _harness(direction: Axis.horizontal, controller: controller),
        );
        await tester.pumpAndSettle();

        controller.hide(0);
        await tester.pumpAndSettle();

        final dividers = find.byType(ResizableContainerDivider);
        expect(dividers, findsNWidgets(2));
        expect(_isHit(tester, dividers.at(0)), isFalse);
        expect(_isHit(tester, dividers.at(1)), isTrue);

        controller.hide(2);
        await tester.pumpAndSettle();
        expect(dividers, findsNWidgets(2));
        expect(_isHit(tester, dividers.at(0)), isFalse);
        expect(_isHit(tester, dividers.at(1)), isFalse);
      });
    });

    group('constraints', () {
      testWidgets('keeps tight constraints', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 400,
                height: 300,
                child: _bareContainer(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.getSize(find.byType(ResizableContainer)),
          const Size(400, 300),
        );
      });

      testWidgets('does not loosen loose constraints', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 400, maxHeight: 300),
                child: _bareContainer(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.getSize(find.byType(ResizableContainer)),
          const Size(400, 300),
        );
      });

      testWidgets('resizes a nested container without touching the outer one',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ResizableContainer(
              direction: Axis.horizontal,
              children: [
                const ResizableChild(child: SizedBox.expand(key: Key('left'))),
                ResizableChild(
                  child: ResizableContainer(
                    direction: Axis.vertical,
                    children: const [
                      ResizableChild(child: SizedBox.expand(key: Key('top'))),
                      ResizableChild(
                        child: SizedBox.expand(key: Key('bottom')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final leftBefore = tester.getSize(find.byKey(const Key('left')));
        final topBefore = tester.getSize(find.byKey(const Key('top')));
        final inner = find.byWidgetPredicate(
          (w) => w is ResizableContainerDivider && w.direction == Axis.vertical,
        );

        await tester.drag(inner, const Offset(0, 60), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(tester.getSize(find.byKey(const Key('left'))), leftBefore);
        expect(
          tester.getSize(find.byKey(const Key('top'))).height,
          moreOrLessEquals(topBefore.height + 40),
        );
      });
    });

    group('repaint isolation', () {
      testWidgets('does not repaint panes that kept their size',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final painters = List.generate(4, (_) => _CountingPainter());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                direction: Axis.horizontal,
                children: [
                  for (final painter in painters)
                    ResizableChild(
                      child: CustomPaint(
                        painter: painter,
                        child: const SizedBox.expand(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final before = painters.map((p) => p.paints).toList();

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(ResizableContainerDivider).at(1)),
        );
        await gesture.moveBy(const Offset(kDragSlopDefault + 1, 0));
        await tester.pump();
        for (var i = 0; i < 10; i++) {
          await gesture.moveBy(const Offset(5, 0));
          await tester.pump();
        }
        await gesture.up();
        await tester.pump();

        expect(painters[0].paints, before[0]);
        expect(painters[3].paints, before[3]);
        expect(painters[1].paints, greaterThan(before[1]));
        expect(painters[2].paints, greaterThan(before[2]));
      });
    });
  });
}

Widget _bareContainer() {
  return const ResizableContainer(
    direction: Axis.horizontal,
    children: [
      ResizableChild(child: SizedBox.expand()),
      ResizableChild(child: SizedBox.expand()),
    ],
  );
}

class _CountingPainter extends CustomPainter {
  int paints = 0;

  @override
  void paint(Canvas canvas, Size size) => paints++;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

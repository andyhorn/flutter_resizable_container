import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_test/flutter_test.dart';

const _surface = Size(600, 400);
const _slop = 20.0;

Widget _harness({
  Axis direction = Axis.horizontal,
  TextDirection textDirection = TextDirection.ltr,
  ResizableDivider divider = const ResizableDivider(
    thickness: 4,
    hitSlop: _slop,
  ),
  Widget? first,
  Widget? second,
  ResizableController? controller,
  ResizableHideAnimation? hideAnimation,
}) {
  final container = ResizableContainer(
    direction: direction,
    controller: controller,
    hideAnimation: hideAnimation,
    children: [
      ResizableChild(
        divider: divider,
        child: first ?? const ColoredBox(key: Key('pane0'), color: Colors.red),
      ),
      ResizableChild(
        child:
            second ?? const ColoredBox(key: Key('pane1'), color: Colors.blue),
      ),
    ],
  );

  return MaterialApp(
    home: Directionality(
      textDirection: textDirection,
      child: Scaffold(body: container),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.binding.setSurfaceSize(_surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

double _paneExtent(WidgetTester tester, String key, Axis direction) {
  final size = tester.getSize(find.byKey(Key(key)));
  return direction == Axis.horizontal ? size.width : size.height;
}

Future<void> _dragFrom(WidgetTester tester, Offset start, Offset delta) async {
  final gesture = await tester.startGesture(start);
  await gesture
      .moveBy(Offset(delta.dx.sign, delta.dy.sign) * (kDragSlopDefault + 1));
  await tester.pump();
  await gesture.moveBy(delta);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  group('ResizableDivider.hitSlop', () {
    test('defaults to 0', () {
      expect(const ResizableDivider().hitSlop, 0);
    });

    test('must not be negative', () {
      expect(() => ResizableDivider(hitSlop: -1), throwsAssertionError);
    });

    test('is part of equality', () {
      expect(
        const ResizableDivider(hitSlop: 8),
        const ResizableDivider(hitSlop: 8),
      );
      expect(
        const ResizableDivider(hitSlop: 8),
        isNot(const ResizableDivider(hitSlop: 9)),
      );
    });

    group('dragging', () {
      testWidgets('resizes when started in the slop zone on either side', (
        tester,
      ) async {
        await _pump(tester, _harness());
        final line = tester.getRect(find.byKey(const Key('pane0')));
        final y = line.center.dy;
        final before = tester.getSize(find.byKey(const Key('pane0'))).width;

        await _dragFrom(
          tester,
          Offset(line.right + _slop - 2, y),
          const Offset(40, 0),
        );
        final afterRight = tester.getSize(find.byKey(const Key('pane0'))).width;
        expect(afterRight, greaterThan(before));

        final divider = tester.getRect(find.byKey(const Key('pane0'))).right;
        await _dragFrom(tester, Offset(divider - 2, y), const Offset(-40, 0));
        expect(
          tester.getSize(find.byKey(const Key('pane0'))).width,
          lessThan(afterRight),
        );
      });

      testWidgets('does not resize from outside the slop zone', (tester) async {
        await _pump(tester, _harness());
        final paneRight = tester.getRect(find.byKey(const Key('pane0'))).right;
        final y = _surface.height / 2;
        final before = tester.getSize(find.byKey(const Key('pane0'))).width;

        await _dragFrom(
            tester, Offset(paneRight - _slop - 5, y), const Offset(40, 0));
        await _dragFrom(
          tester,
          Offset(paneRight + 4 + _slop + 5, y),
          const Offset(40, 0),
        );

        expect(tester.getSize(find.byKey(const Key('pane0'))).width, before);
      });

      testWidgets('resizes under RTL', (tester) async {
        await _pump(tester, _harness(textDirection: TextDirection.rtl));
        final pane = tester.getRect(find.byKey(const Key('pane0')));
        final before = pane.width;

        await _dragFrom(
          tester,
          Offset(pane.left - _slop + 2, pane.center.dy),
          const Offset(-40, 0),
        );

        expect(
          tester.getSize(find.byKey(const Key('pane0'))).width,
          greaterThan(before),
        );
      });

      testWidgets('resizes a vertical container', (tester) async {
        await _pump(tester, _harness(direction: Axis.vertical));
        final pane = tester.getRect(find.byKey(const Key('pane0')));
        final before = pane.height;

        await _dragFrom(
          tester,
          Offset(pane.center.dx, pane.bottom + _slop - 2),
          const Offset(0, 40),
        );

        expect(
          tester.getSize(find.byKey(const Key('pane0'))).height,
          greaterThan(before),
        );
      });

      testWidgets('respects a cross-axis length and alignment', (tester) async {
        await _pump(
          tester,
          _harness(
            divider: const ResizableDivider(
              thickness: 4,
              hitSlop: _slop,
              length: ResizableSize.pixels(100),
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          ),
        );
        final pane = tester.getRect(find.byKey(const Key('pane0')));
        final x = pane.right + _slop - 2;
        final before = pane.width;

        await _dragFrom(tester, Offset(x, pane.top + 150), const Offset(40, 0));
        expect(tester.getSize(find.byKey(const Key('pane0'))).width, before);

        await _dragFrom(tester, Offset(x, pane.top + 50), const Offset(40, 0));
        expect(
          tester.getSize(find.byKey(const Key('pane0'))).width,
          greaterThan(before),
        );
      });

      testWidgets('keeps working while a hide animation runs', (tester) async {
        final controller = ResizableController();
        addTearDown(controller.dispose);
        await tester.binding.setSurfaceSize(_surface);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                controller: controller,
                hideAnimation: const ResizableHideAnimation(),
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    divider: const ResizableDivider(
                      thickness: 4,
                      hitSlop: _slop,
                    ),
                    child: const ColoredBox(
                      key: Key('pane0'),
                      color: Colors.red,
                    ),
                  ),
                  const ResizableChild(
                    divider: ResizableDivider(thickness: 4, hitSlop: _slop),
                    child: ColoredBox(key: Key('pane1'), color: Colors.blue),
                  ),
                  const ResizableChild(
                    child: ColoredBox(key: Key('pane2'), color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        controller.hide(2);
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));

        final dividers = find.byType(ResizableContainerDivider);
        final first = tester.getRect(dividers.first);
        final pane0 = tester.getRect(find.byKey(const Key('pane0')));
        expect(first.left, moreOrLessEquals(pane0.right - _slop));
        await tester.pumpAndSettle();
      });
    });

    group('when hidden', () {
      testWidgets('has no target, ignoring the slop', (tester) async {
        final controller = ResizableController();
        addTearDown(controller.dispose);
        await _pump(tester, _harness(controller: controller));
        expect(
          tester.getSize(find.byType(ResizableContainerDivider)).width,
          4 + 2 * _slop,
        );

        controller.hide(1);
        await tester.pumpAndSettle();

        expect(
          tester.getSize(find.byType(ResizableContainerDivider)).width,
          0,
        );
      });
    });

    group('hover', () {
      testWidgets('shows the resize cursor and fires callbacks in the slop', (
        tester,
      ) async {
        var entered = 0;
        var exited = 0;
        await _pump(
          tester,
          _harness(
            divider: ResizableDivider(
              thickness: 4,
              hitSlop: _slop,
              onHoverEnter: () => entered++,
              onHoverExit: () => exited++,
            ),
          ),
        );
        final paneRight = tester.getRect(find.byKey(const Key('pane0'))).right;
        final y = _surface.height / 2;

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.addPointer(location: Offset(paneRight + _slop - 2, y));
        await tester.pump();

        expect(entered, 1);
        expect(
          RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(
            1,
          ),
          SystemMouseCursors.resizeLeftRight,
        );

        await mouse.moveTo(Offset(paneRight + 4 + _slop + 5, y));
        await tester.pump();
        expect(exited, 1);
      });

      testWidgets('does not hover outside the slop zone', (tester) async {
        var entered = 0;
        await _pump(
          tester,
          _harness(
            divider: ResizableDivider(
              thickness: 4,
              hitSlop: _slop,
              onHoverEnter: () => entered++,
            ),
          ),
        );
        final paneRight = tester.getRect(find.byKey(const Key('pane0'))).right;

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.addPointer(
          location: Offset(paneRight - _slop - 5, _surface.height / 2),
        );
        await tester.pump();

        expect(entered, 0);
      });
    });

    group('scrolling', () {
      testWidgets('still scrolls a pane list started in the slop zone', (
        tester,
      ) async {
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        await _pump(
          tester,
          _harness(
            first: ListView(
              key: const Key('pane0'),
              controller: scroll,
              children: [
                for (var i = 0; i < 50; i++)
                  SizedBox(height: 40, child: Text('row $i')),
              ],
            ),
          ),
        );
        final paneRight = tester.getRect(find.byKey(const Key('pane0'))).right;

        await _dragFrom(
          tester,
          Offset(paneRight - _slop + 2, 200),
          const Offset(0, -150),
        );

        expect(scroll.offset, greaterThan(0));
      });
    });

    group('layout', () {
      testWidgets('does not change the pane sizes', (tester) async {
        await _pump(
          tester,
          _harness(divider: const ResizableDivider(thickness: 4)),
        );
        final without = tester.getSize(find.byKey(const Key('pane0')));

        await _pump(tester, _harness());
        final slopped = tester.getSize(find.byKey(const Key('pane0')));

        expect(slopped, without);
        expect(
          _paneExtent(tester, 'pane1', Axis.horizontal),
          moreOrLessEquals(_surface.width - without.width - 4),
        );
      });
    });
  });
}

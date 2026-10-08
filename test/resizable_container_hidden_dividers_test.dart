import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_test/flutter_test.dart';

const _surfaceMain = 600.0;
const _dividerThickness = 10.0;
const _evenThird = (_surfaceMain - 2 * _dividerThickness) / 3;
const _divider = ResizableDivider(thickness: _dividerThickness);
const _paddedDivider = ResizableDivider(thickness: 10, padding: 6);

Widget _harness({
  required ResizableController controller,
  ResizableHideAnimation? hideAnimation,
  Axis direction = Axis.horizontal,
  List<ResizableChild>? children,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ResizableContainer(
        controller: controller,
        direction: direction,
        hideAnimation: hideAnimation,
        children: children ??
            const [
              ResizableChild(
                divider: _divider,
                child: SizedBox.expand(key: Key('A')),
              ),
              ResizableChild(
                divider: _divider,
                child: SizedBox.expand(key: Key('B')),
              ),
              ResizableChild(
                child: SizedBox.expand(key: Key('C')),
              ),
            ],
      ),
    ),
  );
}

Size _surfaceFor(Axis direction) {
  return direction == Axis.horizontal
      ? const Size(600, 400)
      : const Size(400, 600);
}

double _extent(WidgetTester tester, String key, Axis direction) {
  final size = tester.getSize(find.byKey(Key(key)));
  return direction == Axis.horizontal ? size.width : size.height;
}

Future<ResizableController> _pumpHarness(
  WidgetTester tester, {
  ResizableHideAnimation? hideAnimation,
  Axis direction = Axis.horizontal,
  List<ResizableChild>? children,
  ResizableController? controller,
}) async {
  await tester.binding.setSurfaceSize(_surfaceFor(direction));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final resolved = controller ?? ResizableController();
  addTearDown(resolved.dispose);

  await tester.pumpWidget(
    _harness(
      controller: resolved,
      direction: direction,
      hideAnimation: hideAnimation,
      children: children,
    ),
  );
  await tester.pumpAndSettle();

  return resolved;
}

const _paddedChildren = [
  ResizableChild(
    divider: _paddedDivider,
    child: SizedBox.expand(key: Key('A')),
  ),
  ResizableChild(
    divider: _paddedDivider,
    child: SizedBox.expand(key: Key('B')),
  ),
  ResizableChild(
    child: SizedBox.expand(key: Key('C')),
  ),
];

void main() {
  group('ResizableContainer hidden dividers', () {
    for (final direction in Axis.values) {
      for (final animated in [false, true]) {
        final hideAnimation = animated ? const ResizableHideAnimation() : null;
        final label = animated ? 'with hideAnimation' : 'without hideAnimation';

        group('$label ($direction)', () {
          testWidgets('ratios sum to 1 while a child is hidden',
              (tester) async {
            final controller = await _pumpHarness(
              tester,
              direction: direction,
              hideAnimation: hideAnimation,
            );

            controller.hide(2);
            await tester.pumpAndSettle();

            expect(
              controller.ratios.reduce((a, b) => a + b),
              closeTo(1, 1e-9),
            );
          });

          testWidgets(
              'hiding the last child collapses it and shares the rest evenly',
              (tester) async {
            final controller = await _pumpHarness(
              tester,
              direction: direction,
              hideAnimation: hideAnimation,
            );

            controller.hide(2);
            await tester.pumpAndSettle();

            expect(controller.pixels, [295, 295, 0]);
          });

          testWidgets('hiding a middle child keeps ratios at 1',
              (tester) async {
            final controller = await _pumpHarness(
              tester,
              direction: direction,
              hideAnimation: hideAnimation,
            );

            controller.hide(1);
            await tester.pumpAndSettle();

            expect(
              controller.ratios.reduce((a, b) => a + b),
              closeTo(1, 1e-9),
            );
            expect(
              _extent(tester, 'A', direction) + _extent(tester, 'C', direction),
              600,
            );
          });

          testWidgets('show restores the original sizes and ratios',
              (tester) async {
            final controller = await _pumpHarness(
              tester,
              direction: direction,
              hideAnimation: hideAnimation,
            );
            final originalPixels = List.of(controller.pixels);
            final originalRatios = List.of(controller.ratios);

            controller.hide(2);
            await tester.pumpAndSettle();
            controller.show(2);
            await tester.pumpAndSettle();

            for (var i = 0; i < originalPixels.length; i++) {
              expect(controller.pixels[i], closeTo(originalPixels[i], 1e-9));
              expect(controller.ratios[i], closeTo(originalRatios[i], 1e-9));
            }
            expect(_extent(tester, 'A', direction), closeTo(_evenThird, 0.01));
            expect(_extent(tester, 'C', direction), closeTo(_evenThird, 0.01));
          });
        });
      }

      group('with a padded divider ($direction)', () {
        testWidgets('counts thickness and padding between visible children',
            (tester) async {
          final controller = await _pumpHarness(
            tester,
            direction: direction,
            children: _paddedChildren,
          );

          controller.hide(2);
          await tester.pumpAndSettle();

          expect(
            _extent(tester, 'A', direction) +
                _extent(tester, 'B', direction) +
                16,
            600,
          );
        });

        testWidgets('ignores both dividers around a hidden middle child',
            (tester) async {
          final controller = await _pumpHarness(
            tester,
            direction: direction,
            children: _paddedChildren,
          );

          controller.hide(1);
          await tester.pumpAndSettle();

          expect(
            _extent(tester, 'A', direction) + _extent(tester, 'C', direction),
            600,
          );
        });
      });
    }

    testWidgets('a divider between two visible children still counts',
        (tester) async {
      final controller = await _pumpHarness(tester);

      controller.hide(2);
      await tester.pumpAndSettle();

      expect(
        _extent(tester, 'A', Axis.horizontal) +
            _extent(tester, 'B', Axis.horizontal) +
            10,
        600,
      );
      expect(controller.pixels[2], 0);
    });

    testWidgets('dragging a visible divider resizes its neighbors',
        (tester) async {
      final controller = await _pumpHarness(tester);

      controller.hide(2);
      await tester.pumpAndSettle();
      final before = _extent(tester, 'A', Axis.horizontal);

      await tester.drag(
        find.byType(ResizableContainerDivider).first,
        const Offset(50, 0),
      );
      await tester.pumpAndSettle();

      final a = _extent(tester, 'A', Axis.horizontal);
      final b = _extent(tester, 'B', Axis.horizontal);
      final c = _extent(tester, 'C', Axis.horizontal);
      expect(a, greaterThan(before));
      expect(a + b + _dividerThickness, closeTo(_surfaceMain, 0.01));
      expect(c, 0);
      expect(controller.pixels[2], 0);
    });

    testWidgets('setSizes validates against hidden-aware available space',
        (tester) async {
      final controller = await _pumpHarness(tester);

      controller.hide(2);
      await tester.pumpAndSettle();

      expect(
        () => controller.setSizes(const [
          ResizableSize.pixels(300),
          ResizableSize.pixels(291),
          ResizableSize.pixels(50),
        ]),
        throwsArgumentError,
      );
      expect(
        () => controller.setSizes(const [
          ResizableSize.pixels(300),
          ResizableSize.pixels(290),
          ResizableSize.pixels(50),
        ]),
        returnsNormally,
      );

      controller.show(2);
      expect(controller.sizes[2], const ResizableSize.pixels(50));
    });

    group('hideAnimation', () {
      const animation = ResizableHideAnimation();

      testWidgets('starts from the pre-hide sizes without a jump',
          (tester) async {
        final controller = await _pumpHarness(
          tester,
          hideAnimation: animation,
        );
        final before = [
          _extent(tester, 'A', Axis.horizontal),
          _extent(tester, 'B', Axis.horizontal),
          _extent(tester, 'C', Axis.horizontal),
        ];

        controller.hide(2);
        await tester.pump();
        await tester.pump();

        expect(_extent(tester, 'A', Axis.horizontal), closeTo(before[0], 0.01));
        expect(_extent(tester, 'B', Axis.horizontal), closeTo(before[1], 0.01));
        expect(_extent(tester, 'C', Axis.horizontal), closeTo(before[2], 0.01));
      });

      testWidgets('is not cancelled by its own divider change', (tester) async {
        final controller = await _pumpHarness(
          tester,
          hideAnimation: animation,
        );

        controller.hide(2);
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final mid = _extent(tester, 'C', Axis.horizontal);
        expect(mid, greaterThan(0));
        expect(mid, lessThan(_evenThird + 0.01));
        expect(tester.binding.transientCallbackCount, greaterThan(0));
      });

      testWidgets('is still cancelled by a real resize', (tester) async {
        final controller = await _pumpHarness(
          tester,
          hideAnimation: animation,
        );

        controller.hide(2);
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.binding.transientCallbackCount, greaterThan(0));

        await tester.binding.setSurfaceSize(const Size(800, 400));
        await tester.pump();
        await tester.pump();

        expect(tester.binding.transientCallbackCount, 0);
        expect(_extent(tester, 'C', Axis.horizontal), 0);
      });
    });
  });
}

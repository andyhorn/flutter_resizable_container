import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_test/flutter_test.dart';

const _divider = ResizableDivider(thickness: 10);

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

double _width(WidgetTester tester, String key) =>
    tester.getSize(find.byKey(Key(key))).width;

void main() {
  group('ResizableContainer empty children', () {
    for (final direction in Axis.values) {
      testWidgets('builds without throwing ($direction)', (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 400));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _harness(
            controller: controller,
            direction: direction,
            children: const [],
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(controller.pixels, isEmpty);
      });
    }

    testWidgets('lays out when children arrive after being empty',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _harness(controller: controller, children: const []),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(_harness(controller: controller));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_width(tester, 'A'), closeTo(193.33, 0.01));
      expect(_width(tester, 'B'), closeTo(193.33, 0.01));
      expect(_width(tester, 'C'), closeTo(193.33, 0.01));
    });

    testWidgets('handles children being cleared', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_harness(controller: controller));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _harness(controller: controller, children: const []),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(controller.pixels, isEmpty);
    });
  });

  group('ResizableContainer hidden dividers', () {
    for (final animated in [false, true]) {
      final hideAnimation = animated ? const ResizableHideAnimation() : null;
      final label = animated ? 'with hideAnimation' : 'without hideAnimation';

      group(label, () {
        testWidgets('ratios sum to 1 while a child is hidden', (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            _harness(controller: controller, hideAnimation: hideAnimation),
          );
          await tester.pumpAndSettle();

          controller.hide(2);
          await tester.pumpAndSettle();

          expect(controller.ratios.reduce((a, b) => a + b), closeTo(1, 1e-9));
          expect(controller.pixels, [295, 295, 0]);
        });

        testWidgets('hiding a middle child keeps ratios at 1', (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            _harness(controller: controller, hideAnimation: hideAnimation),
          );
          await tester.pumpAndSettle();

          controller.hide(1);
          await tester.pumpAndSettle();

          expect(controller.ratios.reduce((a, b) => a + b), closeTo(1, 1e-9));
          expect(_width(tester, 'A') + _width(tester, 'C'), 600);
        });

        testWidgets('show restores the original sizes and ratios',
            (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            _harness(controller: controller, hideAnimation: hideAnimation),
          );
          await tester.pumpAndSettle();
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
          expect(_width(tester, 'A'), closeTo(193.33, 0.01));
          expect(_width(tester, 'C'), closeTo(193.33, 0.01));
        });
      });
    }

    testWidgets('a divider between two visible children still counts',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_harness(controller: controller));
      await tester.pumpAndSettle();

      controller.hide(2);
      await tester.pumpAndSettle();

      expect(_width(tester, 'A') + _width(tester, 'B') + 10, 600);
    });

    testWidgets('setSizes validates against hidden-aware available space',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_harness(controller: controller));
      await tester.pumpAndSettle();

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
        await tester.binding.setSurfaceSize(const Size(600, 400));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _harness(controller: controller, hideAnimation: animation),
        );
        await tester.pumpAndSettle();
        final before = [
          _width(tester, 'A'),
          _width(tester, 'B'),
          _width(tester, 'C'),
        ];

        controller.hide(2);
        await tester.pump();
        await tester.pump();

        expect(_width(tester, 'A'), closeTo(before[0], 0.01));
        expect(_width(tester, 'B'), closeTo(before[1], 0.01));
        expect(_width(tester, 'C'), closeTo(before[2], 0.01));
      });

      testWidgets('is not cancelled by its own divider change', (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 400));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _harness(controller: controller, hideAnimation: animation),
        );
        await tester.pumpAndSettle();

        controller.hide(2);
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final mid = _width(tester, 'C');
        expect(mid, greaterThan(0));
        expect(mid, lessThan(193.34));
      });

      testWidgets('is still cancelled by a real resize', (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 400));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _harness(controller: controller, hideAnimation: animation),
        );
        await tester.pumpAndSettle();

        controller.hide(2);
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.binding.transientCallbackCount, greaterThan(0));

        await tester.binding.setSurfaceSize(const Size(800, 400));
        await tester.pump();
        await tester.pump();

        expect(tester.binding.transientCallbackCount, 0);
        expect(_width(tester, 'C'), 0);
      });
    });
  });
}

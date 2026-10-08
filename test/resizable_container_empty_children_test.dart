import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_test/flutter_test.dart';

const _divider = ResizableDivider(thickness: 10);

const _threeChildren = [
  ResizableChild(divider: _divider, child: SizedBox.expand(key: Key('A'))),
  ResizableChild(divider: _divider, child: SizedBox.expand(key: Key('B'))),
  ResizableChild(child: SizedBox.expand(key: Key('C'))),
];

Widget _harness({
  required ResizableController controller,
  required List<ResizableChild> children,
  Axis direction = Axis.horizontal,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ResizableContainer(
        controller: controller,
        direction: direction,
        children: children,
      ),
    ),
  );
}

Future<ResizableController> _pumpHarness(
  WidgetTester tester, {
  required List<ResizableChild> children,
  Axis direction = Axis.horizontal,
}) async {
  await tester.binding.setSurfaceSize(
    direction == Axis.horizontal ? const Size(600, 400) : const Size(400, 600),
  );
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final controller = ResizableController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    _harness(controller: controller, children: children, direction: direction),
  );
  await tester.pumpAndSettle();

  return controller;
}

void main() {
  group('ResizableContainer empty children', () {
    for (final direction in Axis.values) {
      testWidgets('builds without throwing ($direction)', (tester) async {
        final controller = await _pumpHarness(
          tester,
          direction: direction,
          children: const [],
        );

        expect(tester.takeException(), isNull);
        expect(controller.pixels, isEmpty);
      });
    }

    testWidgets('lays out when children arrive after being empty',
        (tester) async {
      final controller = await _pumpHarness(tester, children: const []);

      await tester.pumpWidget(
        _harness(controller: controller, children: _threeChildren),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      for (final key in ['A', 'B', 'C']) {
        expect(
          tester.getSize(find.byKey(Key(key))).width,
          closeTo(193.33, 0.01),
        );
      }
    });

    testWidgets('handles children being cleared', (tester) async {
      final controller = await _pumpHarness(
        tester,
        children: _threeChildren,
      );

      await tester.pumpWidget(
        _harness(controller: controller, children: const []),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(controller.pixels, isEmpty);
    });
  });
}

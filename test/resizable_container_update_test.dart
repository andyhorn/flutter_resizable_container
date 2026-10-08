import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
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

    testWidgets('resets hidden state when keyed children are reordered',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      final controller = ResizableController();

      Widget build(List<String> order) => MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 400,
                child: ResizableContainer(
                  controller: controller,
                  direction: Axis.horizontal,
                  children: [
                    for (final id in order)
                      ResizableChild(
                        key: ValueKey(id),
                        child: const ColoredBox(color: Color(0xFF000000)),
                      ),
                  ],
                ),
              ),
            ),
          );

      await tester.pumpWidget(build(['a', 'b']));
      await tester.pumpAndSettle();

      controller.hide(0);
      await tester.pumpAndSettle();

      await tester.pumpWidget(build(['b', 'a']));
      await tester.pumpAndSettle();

      expect(controller.hiddenIndices, isEmpty);
    });
  });

  group('ResizableContainer remount with an external controller', () {
    Future<void> remount(WidgetTester tester, Widget widget) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    }

    testWidgets('keeps hidden indices and drags when the container remounts',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_RemountApp(controller: controller));
      await tester.pumpAndSettle();

      controller.hide(2);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(ResizableContainerDivider).first,
        const Offset(50, 0),
      );
      await tester.pumpAndSettle();

      final pixelsBefore = List.of(controller.pixels);
      expect(pixelsBefore[2], 0);
      expect(pixelsBefore[0], greaterThan(pixelsBefore[1]));

      await remount(tester, _RemountApp(controller: controller));

      expect(controller.hiddenIndices, {2});
      for (var i = 0; i < pixelsBefore.length; i++) {
        expect(controller.pixels[i], closeTo(pixelsBefore[i], 0.01));
      }
      expect(
        tester.getSize(find.byKey(const Key('A'))).width,
        closeTo(pixelsBefore[0], 0.01),
      );
    });

    testWidgets('adapts to a different available space after a remount',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 400));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_RemountApp(controller: controller));
      await tester.pumpAndSettle();

      controller.hide(2);
      await tester.pumpAndSettle();

      await remount(tester, _RemountApp(controller: controller, width: 800));

      expect(controller.hiddenIndices, {2});
      expect(controller.pixels[2], 0);
      final total = controller.pixels.reduce((a, b) => a + b);
      expect(total, closeTo(800 - 2, 0.01));
    });

    testWidgets('lays out afresh when the direction changes on remount',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_RemountApp(controller: controller));
      await tester.pumpAndSettle();

      controller.hide(2);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(ResizableContainerDivider).first,
        const Offset(50, 0),
      );
      await tester.pumpAndSettle();
      expect(controller.pixels[0], greaterThan(controller.pixels[1]));

      await remount(tester,
          _RemountApp(controller: controller, direction: Axis.vertical));

      expect(controller.hiddenIndices, {2});
      expect(controller.pixels[0], closeTo(controller.pixels[1], 0.01));
      expect(
        tester.getSize(find.byKey(const Key('A'))).height,
        closeTo(controller.pixels[0], 0.01),
      );
    });

    testWidgets('resets when the children change structurally on remount',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_RemountApp(controller: controller));
      await tester.pumpAndSettle();

      controller.hide(1);
      await tester.pumpAndSettle();

      await remount(
        tester,
        _RemountApp(
          controller: controller,
          children: const [
            ResizableChild(child: SizedBox.expand()),
            ResizableChild(child: SizedBox.expand()),
          ],
        ),
      );

      expect(controller.hiddenIndices, isEmpty);
      expect(controller.pixels.length, 2);
      expect(controller.pixels[0], closeTo(299.5, 0.01));
    });

    testWidgets('resets when a declared size changes on remount',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_RemountApp(controller: controller));
      await tester.pumpAndSettle();

      controller.hide(2);
      await tester.pumpAndSettle();

      await remount(
        tester,
        _RemountApp(
          controller: controller,
          children: const [
            ResizableChild(
              size: ResizableSize.pixels(100),
              divider: ResizableDivider(thickness: 2),
              child: SizedBox.expand(),
            ),
            ResizableChild(
              size: ResizableSize.expand(),
              divider: ResizableDivider(thickness: 2),
              child: SizedBox.expand(),
            ),
            ResizableChild(
              size: ResizableSize.expand(),
              child: SizedBox.expand(),
            ),
          ],
        ),
      );

      expect(controller.hiddenIndices, isEmpty);
      expect(controller.pixels[0], closeTo(100, 0.01));
    });

    testWidgets('initialises a fresh controller', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_RemountApp(controller: controller));
      await tester.pumpAndSettle();

      expect(controller.hiddenIndices, isEmpty);
      expect(controller.pixels.length, 3);
      expect(
        controller.pixels.reduce((a, b) => a + b),
        closeTo(600 - 4, 0.01),
      );
    });

    testWidgets('renders the new child widgets when state is kept',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_RemountApp(controller: controller));
      await tester.pumpAndSettle();
      controller.hide(2);
      await tester.pumpAndSettle();

      await remount(
        tester,
        _RemountApp(
          controller: controller,
          children: const [
            ResizableChild(
              size: ResizableSize.expand(),
              divider: ResizableDivider(thickness: 2),
              child: SizedBox.expand(key: Key('A2')),
            ),
            ResizableChild(
              size: ResizableSize.expand(),
              divider: ResizableDivider(thickness: 2),
              child: SizedBox.expand(key: Key('B2')),
            ),
            ResizableChild(
              size: ResizableSize.expand(),
              child: SizedBox.expand(key: Key('C2')),
            ),
          ],
        ),
      );

      expect(find.byKey(const Key('A2')), findsOneWidget);
      expect(find.byKey(const Key('B2')), findsOneWidget);
      expect(controller.hiddenIndices, {2});
    });
  });
}

class _RemountApp extends StatelessWidget {
  const _RemountApp({
    required this.controller,
    this.width = 600,
    this.direction = Axis.horizontal,
    this.children,
  });

  final ResizableController controller;
  final double width;
  final Axis direction;
  final List<ResizableChild>? children;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            height: 400,
            child: ResizableContainer(
              controller: controller,
              direction: direction,
              children: children ??
                  const [
                    ResizableChild(
                      size: ResizableSize.expand(),
                      divider: ResizableDivider(thickness: 2),
                      child: SizedBox.expand(key: Key('A')),
                    ),
                    ResizableChild(
                      size: ResizableSize.expand(),
                      divider: ResizableDivider(thickness: 2),
                      child: SizedBox.expand(key: Key('B')),
                    ),
                    ResizableChild(
                      size: ResizableSize.expand(),
                      child: SizedBox.expand(key: Key('C')),
                    ),
                  ],
            ),
          ),
        ),
      ),
    );
  }
}

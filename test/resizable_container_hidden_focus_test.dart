import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_test/flutter_test.dart';

class _TickerProbe extends StatefulWidget {
  const _TickerProbe({required this.onTick});

  final VoidCallback onTick;

  @override
  State<_TickerProbe> createState() => _TickerProbeState();
}

class _TickerProbeState extends State<_TickerProbe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )
      ..addListener(widget.onTick)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

void main() {
  group('hidden children', () {
    late ResizableController controller;
    late FocusNode firstNode;
    late FocusNode secondNode;

    setUp(() {
      controller = ResizableController();
      firstNode = FocusNode();
      secondNode = FocusNode();
    });

    void registerCleanup(WidgetTester tester) {
      addTearDown(controller.dispose);
      addTearDown(firstNode.dispose);
      addTearDown(secondNode.dispose);
      addTearDown(() => tester.pumpWidget(const SizedBox()));
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }

    Future<void> pumpFields(
      WidgetTester tester, {
      ResizableHideAnimation? hideAnimation,
    }) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      registerCleanup(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              controller: controller,
              direction: Axis.horizontal,
              hideAnimation: hideAnimation,
              children: [
                ResizableChild(
                  child: TextField(focusNode: firstNode),
                ),
                ResizableChild(
                  child: TextField(focusNode: secondNode),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    group('focus', () {
      testWidgets('cannot be requested on a hidden child', (tester) async {
        await pumpFields(tester);

        controller.hide(0);
        await tester.pumpAndSettle();
        firstNode.requestFocus();
        await tester.pump();

        expect(firstNode.hasFocus, isFalse);
      });

      testWidgets('is skipped by tab traversal', (tester) async {
        await pumpFields(tester);

        controller.hide(0);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        expect(firstNode.hasFocus, isFalse);
        expect(secondNode.hasFocus, isTrue);
      });

      testWidgets('is lost when the focused child is hidden', (tester) async {
        await pumpFields(tester);
        firstNode.requestFocus();
        await tester.pump();
        expect(firstNode.hasFocus, isTrue);

        controller.hide(0);
        await tester.pumpAndSettle();

        expect(firstNode.hasFocus, isFalse);
      });

      testWidgets('can be requested again after show', (tester) async {
        await pumpFields(tester);
        controller.hide(0);
        await tester.pumpAndSettle();

        controller.show(0);
        await tester.pumpAndSettle();
        firstNode.requestFocus();
        await tester.pump();

        expect(firstNode.hasFocus, isTrue);
      });

      testWidgets('is excluded immediately when a hide animation starts', (
        tester,
      ) async {
        await pumpFields(
          tester,
          hideAnimation: const ResizableHideAnimation(
            duration: Duration(milliseconds: 200),
          ),
        );
        firstNode.requestFocus();
        await tester.pump();
        expect(firstNode.hasFocus, isTrue);

        controller.hide(0);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(firstNode.hasFocus, isFalse);

        await tester.pumpAndSettle();
      });
    });

    group('tickers', () {
      Future<void> pumpProbes(
        WidgetTester tester,
        List<int> ticks, {
        ResizableHideAnimation? hideAnimation,
      }) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                controller: controller,
                direction: Axis.horizontal,
                hideAnimation: hideAnimation,
                children: [
                  ResizableChild(
                    child: _TickerProbe(onTick: () => ticks[0]++),
                  ),
                  ResizableChild(
                    child: _TickerProbe(onTick: () => ticks[1]++),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
      }

      testWidgets('stop for a hidden child and resume on show', (
        tester,
      ) async {
        final ticks = [0, 0];
        await pumpProbes(tester, ticks);

        controller.hide(0);
        await tester.pump();
        await tester.pump();
        final hiddenBefore = ticks[0];
        final visibleBefore = ticks[1];
        await tester.pump(const Duration(milliseconds: 100));

        expect(ticks[0], hiddenBefore);
        expect(ticks[1], greaterThan(visibleBefore));

        controller.show(0);
        await tester.pump();
        await tester.pump();
        final resumedBefore = ticks[0];
        await tester.pump(const Duration(milliseconds: 100));

        expect(ticks[0], greaterThan(resumedBefore));
      });

      testWidgets('keep running until the hide animation finishes', (
        tester,
      ) async {
        final ticks = [0, 0];
        await pumpProbes(
          tester,
          ticks,
          hideAnimation: const ResizableHideAnimation(
            duration: Duration(milliseconds: 200),
          ),
        );

        controller.hide(0);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        final midAnimation = ticks[0];
        await tester.pump(const Duration(milliseconds: 100));

        expect(ticks[0], greaterThan(midAnimation));

        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        final afterAnimation = ticks[0];
        await tester.pump(const Duration(milliseconds: 100));

        expect(ticks[0], afterAnimation);
      });
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResizableContainer rebuilds', () {
    testWidgets(
      'child widgets do not rebuild while a divider is dragged',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1000));

        final aBuildCounter = _BuildCounter();
        final bBuildCounter = _BuildCounter();

        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                controller: controller,
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    size: const ResizableSize.ratio(0.5),
                    child: _CountingChild(
                      counter: aBuildCounter,
                      key: const Key('BoxA'),
                    ),
                  ),
                  ResizableChild(
                    size: const ResizableSize.ratio(0.5),
                    child: _CountingChild(
                      counter: bBuildCounter,
                      key: const Key('BoxB'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Capture build counts after the initial layout has settled. Multiple
        // setup builds are expected here; the assertions below only care
        // about *additional* builds during the drag.
        final aBaseline = aBuildCounter.count;
        final bBaseline = bBuildCounter.count;
        final preDragWidth =
            tester.getSize(find.byKey(const Key('BoxA'))).width;

        // Track main controller listener firings; the new contract is that
        // drag updates flow through `pixelsListenable` only, leaving the
        // main listener silent.
        var mainNotifyCount = 0;
        controller.addListener(() => mainNotifyCount++);

        // Drive a multi-tick drag — every tick pushes a pixel update through
        // the controller.
        await tester.timedDrag(
          find.byType(ResizableContainerDivider),
          const Offset(120, 0),
          const Duration(milliseconds: 200),
        );
        await tester.pump();

        // Guard against a silent regression where the drag fails to reach
        // the divider (e.g., a placeholder divider with no gesture handler):
        // assert the drag actually moved sizes before claiming no rebuilds.
        final postDragWidth =
            tester.getSize(find.byKey(const Key('BoxA'))).width;
        expect(postDragWidth, greaterThan(preDragWidth));

        expect(aBuildCounter.count, aBaseline);
        expect(bBuildCounter.count, bBaseline);
        expect(mainNotifyCount, 0);
      },
    );

    testWidgets(
      'child widgets do not rebuild while a vertical divider is dragged',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1000));

        final aBuildCounter = _BuildCounter();
        final bBuildCounter = _BuildCounter();

        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                controller: controller,
                direction: Axis.vertical,
                children: [
                  ResizableChild(
                    size: const ResizableSize.ratio(0.5),
                    child: _CountingChild(
                      counter: aBuildCounter,
                      key: const Key('BoxA'),
                    ),
                  ),
                  ResizableChild(
                    size: const ResizableSize.ratio(0.5),
                    child: _CountingChild(
                      counter: bBuildCounter,
                      key: const Key('BoxB'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final aBaseline = aBuildCounter.count;
        final bBaseline = bBuildCounter.count;
        final preDragHeight =
            tester.getSize(find.byKey(const Key('BoxA'))).height;

        var mainNotifyCount = 0;
        controller.addListener(() => mainNotifyCount++);

        await tester.timedDrag(
          find.byType(ResizableContainerDivider),
          const Offset(0, 120),
          const Duration(milliseconds: 200),
        );
        await tester.pump();

        final postDragHeight =
            tester.getSize(find.byKey(const Key('BoxA'))).height;
        expect(postDragHeight, greaterThan(preDragHeight));

        expect(aBuildCounter.count, aBaseline);
        expect(bBuildCounter.count, bBaseline);
        expect(mainNotifyCount, 0);
      },
    );
  });
}

class _BuildCounter {
  int count = 0;
}

class _CountingChild extends StatelessWidget {
  const _CountingChild({required this.counter, super.key});

  final _BuildCounter counter;

  @override
  Widget build(BuildContext context) {
    counter.count++;
    return const SizedBox.expand();
  }
}

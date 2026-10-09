import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_resizable_container/src/resizable_divider_line.dart';
import 'package:flutter_test/flutter_test.dart';

import 'remount_test_helpers.dart';

void main() {
  group(ResizableContainer, () {
    Finder dividers() => find.byType(ResizableContainerDivider);

    group('pane state', () {
      for (final keyed in [true, false]) {
        testWidgets(
          'is never remounted by relayouts (keyed: $keyed)',
          (tester) async {
            await useSurface(tester, const Size(600, 400));
            final inits = <String, int>{};
            final controller = ResizableController();
            addTearDown(controller.dispose);
            final children = buildChildren(inits, keyed: keyed);

            void expectStable(String reason) {
              expect(inits, {'A': 1, 'B': 1, 'C': 1}, reason: reason);
            }

            await tester.pumpWidget(
              buildHarness(controller: controller, children: children),
            );
            await tester.pumpAndSettle();
            expectStable('mount');

            controller.setSizes(const [
              ResizableSize.pixels(100),
              ResizableSize.pixels(200),
              ResizableSize.expand(),
            ]);
            await tester.pumpAndSettle();
            expectStable('setSizes');

            controller.hide(2);
            await tester.pumpAndSettle();
            controller.show(2);
            await tester.pumpAndSettle();
            expectStable('instant hide/show of another child');

            await tester.binding.setSurfaceSize(const Size(700, 400));
            await tester.pumpAndSettle();
            expectStable('available space change');

            await tester.pumpWidget(
              buildHarness(
                controller: controller,
                children: children,
                direction: Axis.vertical,
              ),
            );
            await tester.pumpAndSettle();
            expectStable('direction change');
          },
        );
      }

      testWidgets('survives animated hide and show of a sibling',
          (tester) async {
        await useSurface(tester, const Size(600, 400));
        final inits = <String, int>{};
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildHarness(
            controller: controller,
            children: buildChildren(inits),
            hideAnimation: hideAnimation,
          ),
        );
        await tester.pumpAndSettle();

        controller.hide(1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(inits, {'A': 1, 'B': 1, 'C': 1});
        await tester.pumpAndSettle();

        controller.show(1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(inits, {'A': 1, 'B': 1, 'C': 1});
      });

      testWidgets('keeps keyed panes mounted when a child is appended',
          (tester) async {
        await useSurface(tester, const Size(600, 400));
        final inits = <String, int>{};
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildHarness(
            controller: controller,
            children: buildChildren(inits),
          ),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          buildHarness(
            controller: controller,
            children: buildChildren(inits, names: const ['A', 'B', 'C', 'D']),
          ),
        );
        await tester.pumpAndSettle();

        expect(inits, {'A': 1, 'B': 1, 'C': 1, 'D': 1});
      });
    });

    group('divider state', () {
      testWidgets('is preserved across instant hide and show', (tester) async {
        await useSurface(tester, const Size(600, 400));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildHarness(
            controller: controller,
            children: buildChildren({}),
          ),
        );
        await tester.pumpAndSettle();
        final before = [
          tester.state(dividers().at(0)),
          tester.state(dividers().at(1)),
        ];

        controller.hide(1);
        await tester.pumpAndSettle();
        controller.show(1);
        await tester.pumpAndSettle();

        expect(identical(tester.state(dividers().at(0)), before[0]), isTrue);
        expect(identical(tester.state(dividers().at(1)), before[1]), isTrue);
      });

      testWidgets('is preserved across animated hide and show', (tester) async {
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
        final before = [
          tester.state(dividers().at(0)),
          tester.state(dividers().at(1)),
        ];

        controller.hide(1);
        await tester.pumpAndSettle();
        controller.show(1);
        await tester.pumpAndSettle();

        expect(identical(tester.state(dividers().at(0)), before[0]), isTrue);
        expect(identical(tester.state(dividers().at(1)), before[1]), isTrue);
      });

      group('when its neighbour is hidden', () {
        late int hoverExits;
        late int dragEnds;
        late int hostRebuilds;
        late ResizableController controller;
        late StateSetter hostSetState;

        setUp(() {
          hoverExits = 0;
          dragEnds = 0;
          hostRebuilds = 0;
          controller = ResizableController();
        });

        tearDown(() => controller.dispose());

        Future<void> pumpHost(WidgetTester tester) async {
          final children = buildChildren(
            {},
            divider: ResizableDivider(
              thickness: 2,
              onHoverExit: () => hostSetState(() {
                hoverExits++;
                hostRebuilds++;
              }),
              onDragEnd: () => hostSetState(() {
                dragEnds++;
                hostRebuilds++;
              }),
            ),
          );
          await tester.pumpWidget(
            StatefulBuilder(
              builder: (context, setState) {
                hostSetState = setState;
                return buildHarness(controller: controller, children: children);
              },
            ),
          );
          await tester.pumpAndSettle();
        }

        Future<TestGesture> hoverDivider(WidgetTester tester) async {
          final gesture = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await gesture.addPointer(location: const Offset(1, 1));
          addTearDown(gesture.removePointer);
          await gesture.moveTo(tester.getCenter(dividers().at(0)));
          await tester.pump();
          return gesture;
        }

        testWidgets('fires onHoverExit once and clears the hover',
            (tester) async {
          await useSurface(tester, const Size(600, 400));
          await pumpHost(tester);
          final gesture = await hoverDivider(tester);

          controller.hide(1);
          await tester.pumpAndSettle();

          expect(hoverExits, 1);
          expect(dragEnds, 0);
          expect(hostRebuilds, 1);
          expect(tester.takeException(), isNull);

          await gesture.moveTo(const Offset(1, 1));
          controller.show(1);
          await tester.pumpAndSettle();

          final state = tester.state(dividers().at(0)) as dynamic;
          expect(state.isHovered, isFalse);
          expect(state.isDragging, isFalse);
          expect(hoverExits, 1);
        });

        testWidgets('fires onDragEnd once and clears the drag', (tester) async {
          await useSurface(tester, const Size(600, 400));
          await pumpHost(tester);
          final gesture = await hoverDivider(tester);

          await gesture.down(tester.getCenter(dividers().at(0)));
          await gesture.moveBy(const Offset(20, 0));
          await tester.pump();

          controller.hide(1);
          await tester.pumpAndSettle();
          await gesture.up();
          await tester.pumpAndSettle();

          expect(dragEnds, 1);
          expect(tester.takeException(), isNull);

          controller.show(1);
          await tester.pumpAndSettle();

          final state = tester.state(dividers().at(0)) as dynamic;
          expect(state.isDragging, isFalse);
          expect(state.isHovered, isFalse);
        });
      });
    });

    group('hidden divider', () {
      bool anyScrollAction(WidgetTester tester) {
        var found = false;
        void visit(SemanticsNode node) {
          final data = node.getSemanticsData();
          if (data.hasAction(SemanticsAction.scrollLeft) ||
              data.hasAction(SemanticsAction.scrollRight)) {
            found = true;
          }
          node.visitChildren((child) {
            visit(child);
            return true;
          });
        }

        final root =
            tester.binding.rootPipelineOwner.semanticsOwner!.rootSemanticsNode;
        if (root != null) visit(root);
        return found;
      }

      bool needsPaint(WidgetTester tester, int index) {
        final box = tester.renderObject(
          find
              .descendant(
                of: find.byType(ResizableDividerLine).at(index),
                matching: find.byType(CustomPaint),
              )
              .first,
        );
        return box.debugNeedsPaint;
      }

      testWidgets('has zero size, is not painted, and ignores input',
          (tester) async {
        await useSurface(tester, const Size(600, 400));
        final semantics = tester.ensureSemantics();
        var tapDowns = 0;
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildHarness(
            controller: controller,
            children: buildChildren(
              {},
              divider: ResizableDivider(
                thickness: 2,
                onTapDown: () => tapDowns++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(needsPaint(tester, 0), isFalse);
        final dividerCenter = tester.getCenter(dividers().at(0));
        await tester.tapAt(dividerCenter);
        await tester.pump();
        expect(tapDowns, 1);

        controller.hide(1);
        await tester.pumpAndSettle();

        for (var i = 0; i < 2; i++) {
          expect(tester.getSize(dividers().at(i)).width, 0);
          expect(needsPaint(tester, i), isTrue);
        }
        expect(anyScrollAction(tester), isFalse);
        expect(dividers().hitTestable(), findsNothing);

        await tester.tapAt(dividerCenter);
        await tester.pump();
        expect(tapDowns, 1);

        semantics.dispose();
      });
    });
  });
}

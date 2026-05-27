import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(ResizableContainer, () {
    group('layout', () {
      testWidgets('correctly sizes ratios', (tester) async {
        // total width = 1000px
        // divider space = 2 * 1px = 2px
        // ratios = 0.15 * (1000px - 2px) = 149.7px
        // expand = 1000px - 2px - 149.7px - 149.7px = 698.6px
        await tester.binding.setSurfaceSize(const Size(1000, 1000));
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    size: ResizableSize.ratio(0.15),
                    child: SizedBox.expand(
                      key: Key('BoxA'),
                    ),
                  ),
                  ResizableChild(
                    child: SizedBox.expand(
                      key: Key('BoxB'),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.ratio(0.15),
                    child: SizedBox.expand(
                      key: Key('BoxC'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
        final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));
        final boxCSize = tester.getSize(find.byKey(const Key('BoxC')));

        expect(boxASize.width, equals(149.7));
        expect(boxBSize.width, equals(698.6));
        expect(boxCSize.width, equals(149.7));
      });

      testWidgets('correctly sizes expands', (tester) async {
        // total width = 1000px
        // divider space = 2 * 1px = 2px
        // num flex = 5
        // space per flex = 1000px - 2px = 998px / 5 = 199.6px
        await tester.binding.setSurfaceSize(const Size(1000, 1000));
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    size: ResizableSize.expand(flex: 1),
                    child: SizedBox.expand(
                      key: Key('BoxA'),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.expand(flex: 2),
                    child: SizedBox.expand(
                      key: Key('BoxB'),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.expand(flex: 2),
                    child: SizedBox.expand(
                      key: Key('BoxC'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
        final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));
        final boxCSize = tester.getSize(find.byKey(const Key('BoxC')));

        expect(boxASize.width, equals(199.6));
        expect(boxBSize.width, equals(399.2));
        expect(boxCSize.width, equals(399.2));
      });

      testWidgets('correctly sizes expands with min constraints',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1000));

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    size: ResizableSize.pixels(500),
                    child: SizedBox.expand(
                      key: Key('BoxA'),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.expand(),
                    child: SizedBox.expand(
                      key: Key('BoxB'),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.expand(flex: 1, min: 300),
                    child: SizedBox.expand(
                      key: Key('BoxC'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
        final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));
        final boxCSize = tester.getSize(find.byKey(const Key('BoxC')));

        expect(boxASize.width, equals(500));
        expect(boxBSize.width, equals(198)); // account for two 1px dividers
        expect(boxCSize.width, equals(300));
      });

      testWidgets('correctly sizes expands with max constraints',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1000));

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    size: ResizableSize.pixels(500),
                    child: SizedBox.expand(
                      key: Key('BoxA'),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.expand(),
                    child: SizedBox.expand(
                      key: Key('BoxB'),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.expand(max: 100),
                    child: SizedBox.expand(
                      key: Key('BoxC'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
        final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));
        final boxCSize = tester.getSize(find.byKey(const Key('BoxC')));

        expect(boxASize.width, equals(500));
        expect(boxBSize.width, equals(398)); // account for two 1px dividers
        expect(boxCSize.width, equals(100));
      });

      testWidgets('correctly sizes shrinks', (tester) async {
        // total space = 1000px
        // divider space = 2 * 1px = 2px
        await tester.binding.setSurfaceSize(const Size(1000, 1000));

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              direction: Axis.horizontal,
              children: [
                ResizableChild(
                  size: ResizableSize.shrink(),
                  child: SizedBox(
                    width: 200,
                    key: Key('BoxA'),
                  ),
                ),
                ResizableChild(
                  size: ResizableSize.shrink(),
                  child: SizedBox(
                    width: 400,
                    key: Key('BoxB'),
                  ),
                ),
                ResizableChild(
                  size: ResizableSize.expand(),
                  child: SizedBox(
                    key: Key('BoxC'),
                  ),
                ),
              ],
            ),
          ),
        ));

        await tester.pumpAndSettle();

        final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
        final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));
        final boxCSize = tester.getSize(find.byKey(const Key('BoxC')));

        expect(boxASize.width, equals(200));
        expect(boxBSize.width, equals(400));
        expect(boxCSize.width, equals(398));
      });

      // Regression test for issue #85: shrink should reflect the child's
      // rendered size even when the child is a SingleChildScrollView,
      // whose intrinsic main-axis dimension is 0.
      testWidgets(
        'shrink measures actual content size for SingleChildScrollView',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(1000, 1000));

          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                direction: Axis.vertical,
                children: [
                  ResizableChild(
                    size: ResizableSize.shrink(),
                    child: SingleChildScrollView(
                      child: SizedBox(
                        height: 150,
                        key: Key('ScrollContent'),
                      ),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.expand(),
                    child: SizedBox(key: Key('Expand')),
                  ),
                ],
              ),
            ),
          ));

          await tester.pumpAndSettle();

          final scrollSize = tester.getSize(
            find.byKey(const Key('ScrollContent')).first,
          );
          expect(scrollSize.height, equals(150));
        },
      );

      testWidgets('correctly sizes pixels', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1000));
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    size: ResizableSize.pixels(200),
                    child: SizedBox.expand(
                      key: Key('BoxA'),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.expand(),
                    child: SizedBox.expand(
                      key: Key('BoxB'),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.pixels(500),
                    child: SizedBox.expand(
                      key: Key('BoxC'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
        final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));
        final boxCSize = tester.getSize(find.byKey(const Key('BoxC')));

        expect(boxASize.width, equals(200));
        expect(boxBSize.width, equals(298));
        expect(boxCSize.width, equals(500));
      });

      testWidgets('respects min size of ratio', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1000));

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    size: ResizableSize.ratio(0.25, min: 400),
                    child: SizedBox.expand(
                      key: Key('BoxA'),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.expand(),
                    child: SizedBox.expand(
                      key: Key('BoxB'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
        final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));

        expect(boxASize.width, equals(400));
        expect(boxBSize.width, equals(599));
      });

      testWidgets('respects max size of ratio', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1000));

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    size: ResizableSize.ratio(0.75, max: 400),
                    child: SizedBox.expand(
                      key: Key('BoxA'),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.expand(),
                    child: SizedBox.expand(
                      key: Key('BoxB'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
        final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));

        expect(boxASize.width, equals(400));
        expect(boxBSize.width, equals(599));
      });

      testWidgets('respects min size of pixels', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1000));

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    size: ResizableSize.pixels(400, min: 500),
                    child: SizedBox.expand(
                      key: Key('BoxA'),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.expand(),
                    child: SizedBox.expand(
                      key: Key('BoxB'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
        final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));

        expect(boxASize.width, equals(500));
        expect(boxBSize.width, equals(499));
      });

      testWidgets('respects max size of pixels', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1000));

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    size: ResizableSize.pixels(400, max: 300),
                    child: SizedBox.expand(
                      key: Key('BoxA'),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.expand(),
                    child: SizedBox.expand(
                      key: Key('BoxB'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
        final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));

        expect(boxASize.width, equals(300));
        expect(boxBSize.width, equals(699));
      });

      testWidgets('respects min size of shrink', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1000));

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    size: ResizableSize.shrink(min: 500),
                    child: SizedBox(
                      width: 200,
                      key: Key('BoxA'),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.expand(),
                    child: SizedBox(
                      key: Key('BoxB'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
        final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));

        expect(boxASize.width, equals(500));
        expect(boxBSize.width, equals(499));
      });

      testWidgets('respects max size of shrink', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1000));

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    size: ResizableSize.shrink(max: 300),
                    child: SizedBox(
                      width: 400,
                      key: Key('BoxA'),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.expand(),
                    child: SizedBox(
                      key: Key('BoxB'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
        final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));

        expect(boxASize.width, equals(300));
        expect(boxBSize.width, equals(699));
      });

      testWidgets('respects min size of expand', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1000));

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    size: ResizableSize.expand(min: 700),
                    child: SizedBox.expand(
                      key: Key('BoxA'),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.expand(),
                    child: SizedBox.expand(
                      key: Key('BoxB'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
        final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));

        expect(boxASize.width, equals(700));
        expect(boxBSize.width, equals(299));
      });

      testWidgets('respects max size of expand', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1000));

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    size: ResizableSize.expand(max: 300),
                    child: SizedBox.expand(
                      key: Key('BoxA'),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.expand(),
                    child: SizedBox.expand(
                      key: Key('BoxB'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
        final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));

        expect(boxASize.width, equals(300));
        expect(boxBSize.width, equals(699));
      });
    });

    testWidgets('can resize by dragging divider', (tester) async {
      const dividerWidth = 2.0;
      final controller = ResizableController();

      await tester.binding.setSurfaceSize(const Size(1000, 1000));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              controller: controller,
              direction: Axis.horizontal,
              children: const [
                ResizableChild(
                  divider: ResizableDivider(
                    thickness: dividerWidth,
                  ),
                  size: ResizableSize.ratio(0.5),
                  child: SizedBox.expand(
                    key: Key('BoxA'),
                  ),
                ),
                ResizableChild(
                  size: ResizableSize.ratio(0.5),
                  child: SizedBox.expand(
                    key: Key('BoxB'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final resizableContainer = tester.widget(find.byType(ResizableContainer));
      expect(resizableContainer, isNotNull);

      final handle = find.byType(ResizableContainerDivider).first;
      expect(handle, isNotNull);

      await tester.drag(handle, const Offset(100, 0));
      await tester.pump();

      expect(controller.ratios.map((r) => (r * 10).round()), [6, 4]);

      final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
      final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));

      expect(boxASize.width, equals(controller.pixels.first));
      expect(boxBSize.width, equals(controller.pixels.last));
    });

    testWidgets('can resize using the controller', (tester) async {
      const dividerWidth = 2.0;
      final controller = ResizableController();

      await tester.binding.setSurfaceSize(const Size(1000, 1000));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              controller: controller,
              direction: Axis.horizontal,
              children: const [
                ResizableChild(
                  divider: ResizableDivider(
                    thickness: dividerWidth,
                  ),
                  child: SizedBox.expand(
                    key: Key('BoxA'),
                  ),
                ),
                ResizableChild(
                  child: SizedBox.expand(
                    key: Key('BoxB'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      const availableSpace = 1000 - dividerWidth;

      final resizableContainer = tester.widget(find.byType(ResizableContainer));
      expect(resizableContainer, isNotNull);

      controller.setSizes(const [
        ResizableSize.ratio(0.6),
        ResizableSize.ratio(0.4),
      ]);

      await tester.pump();

      final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
      final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));

      expect(boxASize, const Size(availableSpace * 0.6, 1000));
      expect(boxBSize, const Size(availableSpace * 0.4, 1000));
    });

    testWidgets('container respects min size', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1000));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              direction: Axis.horizontal,
              children: [
                ResizableChild(
                  size: ResizableSize.expand(min: 200),
                  child: SizedBox.expand(
                    key: Key('BoxA'),
                  ),
                ),
                ResizableChild(child: SizedBox.expand()),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(ResizableContainerDivider),
        const Offset(-600, 0),
      );
      await tester.pump();

      final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
      expect(boxASize, const Size(200, 1000));
    });

    testWidgets('container respects max size', (tester) async {
      const dividerWidth = 2.0;
      await tester.binding.setSurfaceSize(const Size(1000, 1000));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              direction: Axis.horizontal,
              children: [
                ResizableChild(
                  divider: ResizableDivider(
                    thickness: dividerWidth,
                  ),
                  size: ResizableSize.expand(max: 700),
                  child: SizedBox.expand(
                    key: Key('BoxA'),
                  ),
                ),
                ResizableChild(
                  child: SizedBox.expand(
                    key: Key('BoxB'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(ResizableContainerDivider),
        const Offset(600, 0),
      );
      await tester.pump();

      final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
      expect(boxASize, const Size(700, 1000));

      final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));
      expect(boxBSize, const Size(300 - dividerWidth, 1000));
    });

    testWidgets('adjacent containers resize correctly', (tester) async {
      const dividerWidth = 2.0;
      await tester.binding.setSurfaceSize(const Size(1000, 1000));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              direction: Axis.horizontal,
              children: [
                ResizableChild(
                  divider: ResizableDivider(
                    thickness: dividerWidth,
                  ),
                  size: ResizableSize.expand(min: 200),
                  child: SizedBox.expand(
                    key: Key('BoxA'),
                  ),
                ),
                ResizableChild(
                  child: SizedBox.expand(
                    key: Key('BoxB'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(ResizableContainerDivider),
        const Offset(-600, 0),
      );
      await tester.pump();

      final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
      expect(boxASize, const Size(200, 1000));

      final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));
      expect(boxBSize, const Size(800 - dividerWidth, 1000));
    });

    testWidgets('children expand appropriately', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1000));
      await tester.pumpWidget(const _ToggleChildApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ChildA')), findsOneWidget);
      expect(find.byKey(const Key('ChildB')), findsOneWidget);

      expect(
        tester.getSize(find.byKey(const Key('ChildA'))).width,
        moreOrLessEquals((1000 - 2) * (2 / 3), epsilon: 1),
      );
      expect(
        tester.getSize(find.byKey(const Key('ChildB'))).width,
        moreOrLessEquals((1000 - 2) * (1 / 3), epsilon: 1),
      );

      await tester.tap(find.byKey(const Key('ToggleSwitch')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ChildA')), findsOneWidget);
      expect(find.byKey(const Key('ChildB')), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key('ChildA'))).width,
        equals(1000),
      );
    });

    testWidgets('children shrink appropriately', (tester) async {
      final controller = ResizableController();
      await tester.binding.setSurfaceSize(const Size(1000, 1000));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              controller: controller,
              direction: Axis.horizontal,
              children: const [
                ResizableChild(
                  divider: ResizableDivider(
                    thickness: 1,
                  ),
                  size: ResizableSize.expand(),
                  child: SizedBox.expand(
                    key: Key('BoxA'),
                  ),
                ),
                ResizableChild(
                  size: ResizableSize.shrink(),
                  child: SizedBox(
                    width: 200,
                    key: Key('BoxB'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final boxAFinder = find.byKey(const Key('BoxA'));
      final boxBFinder = find.byKey(const Key('BoxB'));

      expect(boxAFinder, findsOneWidget);
      expect(boxBFinder, findsOneWidget);

      final boxASize = tester.getSize(boxAFinder);
      final boxBSize = tester.getSize(boxBFinder);

      expect(boxASize.width, moreOrLessEquals(800, epsilon: 2));
      expect(boxBSize.width, moreOrLessEquals(200, epsilon: 2));

      expect(controller.pixels.first, moreOrLessEquals(800, epsilon: 2));
      expect(controller.pixels.last, moreOrLessEquals(200, epsilon: 2));
    });

    group('when changing the screen size', () {
      group('with a shrink and expand child', () {
        testWidgets(
          'delta is distributed to the expand',
          (tester) async {
            final controller = ResizableController();
            await tester.binding.setSurfaceSize(const Size(1000, 1000));
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: ResizableContainer(
                    controller: controller,
                    direction: Axis.horizontal,
                    children: const [
                      ResizableChild(
                        divider: ResizableDivider(
                          thickness: 1,
                        ),
                        size: ResizableSize.shrink(),
                        child: SizedBox(
                          width: 200,
                          key: Key('BoxA'),
                        ),
                      ),
                      ResizableChild(
                        size: ResizableSize.expand(),
                        child: SizedBox.expand(
                          key: Key('BoxB'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            await tester.pumpAndSettle();

            final boxAFinder = find.byKey(const Key('BoxA'));
            final boxBFinder = find.byKey(const Key('BoxB'));

            expect(boxAFinder, findsOneWidget);
            expect(boxBFinder, findsOneWidget);

            final boxASize = tester.getSize(boxAFinder);
            final boxBSize = tester.getSize(boxBFinder);

            expect(boxASize.width, moreOrLessEquals(200, epsilon: 2));
            expect(boxBSize.width, moreOrLessEquals(800, epsilon: 2));

            await tester.binding.setSurfaceSize(const Size(1100, 1000));
            await tester.pumpAndSettle();

            final newBoxASize = tester.getSize(boxAFinder);
            final newBoxBSize = tester.getSize(boxBFinder);

            expect(newBoxASize.width, moreOrLessEquals(200, epsilon: 2));
            expect(newBoxBSize.width, moreOrLessEquals(900, epsilon: 2));
          },
        );

        testWidgets(
          'if the expand reaches 0, shrink will receive remaining delta',
          (tester) async {
            final controller = ResizableController();
            await tester.binding.setSurfaceSize(const Size(1000, 1000));
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: ResizableContainer(
                    controller: controller,
                    direction: Axis.horizontal,
                    children: const [
                      ResizableChild(
                        divider: ResizableDivider(
                          thickness: 1,
                        ),
                        size: ResizableSize.shrink(),
                        child: SizedBox(
                          width: 200,
                          key: Key('BoxA'),
                        ),
                      ),
                      ResizableChild(
                        size: ResizableSize.expand(),
                        child: SizedBox(
                          key: Key('BoxB'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            await tester.pumpAndSettle();

            final boxAFinder = find.byKey(const Key('BoxA'));
            final boxBFinder = find.byKey(const Key('BoxB'));

            expect(boxAFinder, findsOneWidget);
            expect(boxBFinder, findsOneWidget);

            final boxASize = tester.getSize(boxAFinder);
            final boxBSize = tester.getSize(boxBFinder);

            expect(boxASize.width, moreOrLessEquals(200, epsilon: 2));
            expect(boxBSize.width, moreOrLessEquals(800, epsilon: 2));

            await tester.binding.setSurfaceSize(const Size(150, 1000));
            await tester.pumpAndSettle();

            final newBoxASize = tester.getSize(boxAFinder);
            final newBoxBSize = tester.getSize(boxBFinder);

            expect(newBoxASize.width, moreOrLessEquals(150, epsilon: 2));
            expect(newBoxBSize.width, moreOrLessEquals(0, epsilon: 2));
          },
        );

        testWidgets(
          'if the expand reaches a max constraint, shrink will receive remaining delta',
          (tester) async {
            final controller = ResizableController();
            await tester.binding.setSurfaceSize(const Size(1000, 1000));
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: ResizableContainer(
                    controller: controller,
                    direction: Axis.horizontal,
                    children: const [
                      ResizableChild(
                        divider: ResizableDivider(
                          thickness: 1,
                        ),
                        size: ResizableSize.shrink(),
                        child: SizedBox(
                          width: 200,
                          key: Key('BoxA'),
                        ),
                      ),
                      ResizableChild(
                        size: ResizableSize.expand(max: 850),
                        child: SizedBox(
                          key: Key('BoxB'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            await tester.pumpAndSettle();

            final boxAFinder = find.byKey(const Key('BoxA'));
            final boxBFinder = find.byKey(const Key('BoxB'));

            expect(boxAFinder, findsOneWidget);
            expect(boxBFinder, findsOneWidget);

            final boxASize = tester.getSize(boxAFinder);
            final boxBSize = tester.getSize(boxBFinder);

            expect(boxASize.width, moreOrLessEquals(200, epsilon: 2));
            expect(boxBSize.width, moreOrLessEquals(800, epsilon: 2));

            await tester.binding.setSurfaceSize(const Size(1200, 1000));
            await tester.pumpAndSettle();

            final newBoxASize = tester.getSize(boxAFinder);
            final newBoxBSize = tester.getSize(boxBFinder);

            expect(newBoxASize.width, moreOrLessEquals(350, epsilon: 2));
            expect(newBoxBSize.width, moreOrLessEquals(850, epsilon: 2));
          },
        );
      });

      group('with a shrink and pixel child', () {
        testWidgets('delta is distributed evenly', (tester) async {
          final controller = ResizableController();
          await tester.binding.setSurfaceSize(const Size(500, 500));
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ResizableContainer(
                  controller: controller,
                  direction: Axis.horizontal,
                  children: const [
                    ResizableChild(
                      divider: ResizableDivider(
                        thickness: 1,
                      ),
                      size: ResizableSize.shrink(),
                      child: SizedBox(
                        width: 150,
                        key: Key('BoxA'),
                      ),
                    ),
                    ResizableChild(
                      size: ResizableSize.pixels(300),
                      child: SizedBox(
                        key: Key('BoxB'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          final boxAFinder = find.byKey(const Key('BoxA'));
          final boxBFinder = find.byKey(const Key('BoxB'));

          expect(boxAFinder, findsOneWidget);
          expect(boxBFinder, findsOneWidget);

          final boxASize = tester.getSize(boxAFinder);
          final boxBSize = tester.getSize(boxBFinder);

          expect(boxASize.width, moreOrLessEquals(150, epsilon: 2));
          expect(boxBSize.width, moreOrLessEquals(300, epsilon: 2));

          await tester.binding.setSurfaceSize(const Size(600, 500));
          await tester.pumpAndSettle();

          final newBoxASize = tester.getSize(boxAFinder);
          final newBoxBSize = tester.getSize(boxBFinder);

          expect(newBoxASize.width, moreOrLessEquals(200, epsilon: 2));
          expect(newBoxBSize.width, moreOrLessEquals(350, epsilon: 2));
        });
      });

      group('with two pixel children', () {
        testWidgets('delta is distributed evenly', (tester) async {
          final controller = ResizableController();
          await tester.binding.setSurfaceSize(const Size(502, 500));
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ResizableContainer(
                  controller: controller,
                  direction: Axis.horizontal,
                  children: const [
                    ResizableChild(
                      divider: ResizableDivider(
                        thickness: 1,
                      ),
                      size: ResizableSize.pixels(200),
                      child: SizedBox(
                        key: Key('BoxA'),
                      ),
                    ),
                    ResizableChild(
                      size: ResizableSize.pixels(300),
                      child: SizedBox(
                        key: Key('BoxB'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          final boxAFinder = find.byKey(const Key('BoxA'));
          final boxBFinder = find.byKey(const Key('BoxB'));

          expect(boxAFinder, findsOneWidget);
          expect(boxBFinder, findsOneWidget);

          final boxASize = tester.getSize(boxAFinder);
          final boxBSize = tester.getSize(boxBFinder);

          expect(boxASize.width, moreOrLessEquals(200, epsilon: 2));
          expect(boxBSize.width, moreOrLessEquals(300, epsilon: 2));

          await tester.binding.setSurfaceSize(const Size(600, 500));
          await tester.pumpAndSettle();

          final newBoxASize = tester.getSize(boxAFinder);
          final newBoxBSize = tester.getSize(boxBFinder);

          expect(newBoxASize.width, moreOrLessEquals(250, epsilon: 2));
          expect(newBoxBSize.width, moreOrLessEquals(350, epsilon: 2));
        });
      });
    });

    testWidgets('adjusts child sizes correctly when RTL', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1000));
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: ResizableContainer(
                direction: Axis.horizontal,
                children: const [
                  ResizableChild(
                    divider: ResizableDivider(
                      thickness: 1,
                    ),
                    size: ResizableSize.expand(),
                    child: SizedBox.expand(
                      key: Key('BoxA'),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.expand(),
                    child: SizedBox.expand(
                      key: Key('BoxB'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final boxAFinder = find.byKey(const Key('BoxA'));
      final boxBFinder = find.byKey(const Key('BoxB'));

      final boxASize = tester.getSize(boxAFinder);
      final boxBSize = tester.getSize(boxBFinder);

      expect(boxASize.width, moreOrLessEquals(500, epsilon: 2));
      expect(boxBSize.width, moreOrLessEquals(500, epsilon: 2));

      final centerA = tester.getCenter(find.byKey(const Key('BoxA')));
      final centerB = tester.getCenter(find.byKey(const Key('BoxB')));

      expect(centerA.dx, greaterThan(centerB.dx));

      await tester.drag(
        find.byType(ResizableContainerDivider),
        const Offset(100, 0),
      );

      await tester.pump();

      final boxASizeAfter = tester.getSize(boxAFinder);
      final boxBSizeAfter = tester.getSize(boxBFinder);

      expect(boxASizeAfter.width, lessThan(boxASize.width));
      expect(boxBSizeAfter.width, greaterThan(boxBSize.width));
    });

    testWidgets('fires drag events', (tester) async {
      var dragStart = false;
      var dragEnd = false;

      await tester.binding.setSurfaceSize(const Size(1000, 1000));
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: ResizableContainer(
                direction: Axis.horizontal,
                children: [
                  ResizableChild(
                    divider: ResizableDivider(
                      onDragStart: () => dragStart = true,
                      onDragEnd: () => dragEnd = true,
                    ),
                    size: ResizableSize.expand(),
                    child: SizedBox.expand(
                      key: Key('BoxA'),
                    ),
                  ),
                  ResizableChild(
                    size: ResizableSize.expand(),
                    child: SizedBox.expand(
                      key: Key('BoxB'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final divider = find.byType(ResizableContainerDivider);
      expect(divider, findsOneWidget);

      await tester.drag(divider, Offset(1 + kDragSlopDefault, 0));
      await tester.pump();

      expect(dragStart, isTrue);
      expect(dragEnd, isTrue);
    });

    group('when changing direction', () {
      testWidgets('children are resized correctly', (tester) async {
        final controller = ResizableController();
        var direction = Axis.horizontal;
        await tester.binding.setSurfaceSize(const Size(1000, 1000));
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  appBar: AppBar(
                    actions: [
                      MaterialButton(
                        onPressed: () {
                          setState(() => direction = Axis.vertical);
                        },
                        child: const Text('Click Me!'),
                      ),
                    ],
                  ),
                  body: ResizableContainer(
                    controller: controller,
                    direction: direction,
                    children: const [
                      ResizableChild(
                        divider: ResizableDivider(
                          thickness: 1,
                        ),
                        size: ResizableSize.expand(),
                        child: SizedBox.expand(
                          key: Key('BoxA'),
                        ),
                      ),
                      ResizableChild(
                        size: ResizableSize.shrink(),
                        child: SizedBox(
                          width: 200,
                          key: Key('BoxB'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        final boxAFinder = find.byKey(const Key('BoxA'));
        final boxBFinder = find.byKey(const Key('BoxB'));

        expect(boxAFinder, findsOneWidget);
        expect(boxBFinder, findsOneWidget);

        final boxASize = tester.getSize(boxAFinder);
        final boxBSize = tester.getSize(boxBFinder);

        expect(boxASize.width, moreOrLessEquals(800, epsilon: 2));
        expect(boxBSize.width, moreOrLessEquals(200, epsilon: 2));

        await tester.tap(find.text('Click Me!'));
        await tester.pumpAndSettle();

        final newBoxASize = tester.getSize(boxAFinder);
        final newBoxBSize = tester.getSize(boxBFinder);

        expect(newBoxASize.height,
            moreOrLessEquals(1000 - kToolbarHeight, epsilon: 2));
        expect(newBoxBSize.height, moreOrLessEquals(0, epsilon: 2));
      });
    });

    group('when cascading is enabled', () {
      testWidgets('negative deltas are applied to siblings', (tester) async {
        await tester.binding.setSurfaceSize(const Size(303, 500));
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: ResizableContainer(
                    cascadeNegativeDelta: true,
                    direction: Axis.horizontal,
                    children: const [
                      ResizableChild(
                        size: ResizableSize.expand(),
                        divider: ResizableDivider(
                          thickness: 2,
                        ),
                        child: SizedBox.expand(
                          key: Key('BoxA'),
                        ),
                      ),
                      ResizableChild(
                        size: ResizableSize.expand(min: 50),
                        child: SizedBox.expand(
                          key: Key('BoxB'),
                        ),
                      ),
                      ResizableChild(
                        size: ResizableSize.expand(min: 50),
                        child: SizedBox.expand(
                          key: Key('BoxC'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        final handle = find.byType(ResizableContainerDivider).first;
        expect(handle, isNotNull);

        await tester.drag(handle, const Offset(kDragSlopDefault + 55, 0));
        await tester.pump();

        final boxAFinder = find.byKey(const Key('BoxA'));
        final boxBFinder = find.byKey(const Key('BoxB'));
        final boxCFinder = find.byKey(const Key('BoxC'));

        final boxASize = tester.getSize(boxAFinder);
        final boxBSize = tester.getSize(boxBFinder);
        final boxCSize = tester.getSize(boxCFinder);

        expect(boxASize.width, equals(155));
        expect(boxBSize.width, equals(50));
        expect(boxCSize.width, equals(95));
      });
    });

    group('hideAnimation', () {
      Widget buildHarness({
        required ResizableController controller,
        ResizableHideAnimation? hideAnimation,
      }) {
        return MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              controller: controller,
              direction: Axis.horizontal,
              hideAnimation: hideAnimation,
              children: const [
                ResizableChild(
                  size: ResizableSize.pixels(200),
                  divider: ResizableDivider(thickness: 2),
                  child: SizedBox.expand(key: Key('A')),
                ),
                ResizableChild(
                  size: ResizableSize.pixels(200),
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
        );
      }

      testWidgets(
        'collapses immediately when hideAnimation is null',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(buildHarness(controller: controller));
          await tester.pumpAndSettle();

          controller.hide(1);
          await tester.pumpAndSettle();

          expect(tester.getSize(find.byKey(const Key('B'))).width, 0);
          // Both dividers adjacent to the hidden child are also removed.
          expect(find.byType(ResizableContainerDivider), findsNothing);
        },
      );

      testWidgets(
        'interpolates the hidden child width between start and target',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            buildHarness(
              controller: controller,
              hideAnimation: const ResizableHideAnimation(),
            ),
          );
          await tester.pumpAndSettle();

          final initialWidth = tester.getSize(find.byKey(const Key('B'))).width;
          expect(initialWidth, 200);

          controller.hide(1);
          // pump #1: capture-target frame, schedules animation start in
          // its post-frame callback.
          await tester.pump();
          // pump #2: first ticker tick — Ticker captures its start time on
          // the first tick, so elapsed is 0 here.
          await tester.pump();
          // pump #3: advances halfway through the 200ms animation.
          await tester.pump(const Duration(milliseconds: 100));

          final midWidth = tester.getSize(find.byKey(const Key('B'))).width;
          expect(midWidth, lessThan(initialWidth));
          expect(midWidth, greaterThan(0));
        },
      );

      testWidgets(
        'reaches zero width and lets siblings absorb the freed space',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            buildHarness(
              controller: controller,
              hideAnimation: const ResizableHideAnimation(),
            ),
          );
          await tester.pumpAndSettle();

          controller.hide(1);
          await tester.pumpAndSettle();

          expect(tester.getSize(find.byKey(const Key('B'))).width, 0);
          // A=200, B=0, dividers collapsed, so C absorbs the rest.
          expect(
            tester.getSize(find.byKey(const Key('C'))).width,
            equals(400),
          );
        },
      );

      testWidgets(
        'keeps the adjacent divider in the tree during the collapse',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            buildHarness(
              controller: controller,
              hideAnimation: const ResizableHideAnimation(),
            ),
          );
          await tester.pumpAndSettle();

          controller.hide(1);
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          // Both dividers adjacent to the collapsing child are still
          // rendered during the in-flight collapse.
          expect(find.byType(ResizableContainerDivider), findsNWidgets(2));
        },
      );

      testWidgets(
        'removes the adjacent divider once the animation settles',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            buildHarness(
              controller: controller,
              hideAnimation: const ResizableHideAnimation(),
            ),
          );
          await tester.pumpAndSettle();

          controller.hide(1);
          await tester.pumpAndSettle();

          // Both dividers adjacent to the hidden child are removed.
          expect(find.byType(ResizableContainerDivider), findsNothing);
        },
      );

      testWidgets(
        'animates the restored size on show',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            buildHarness(
              controller: controller,
              hideAnimation: const ResizableHideAnimation(),
            ),
          );
          await tester.pumpAndSettle();

          controller.hide(1);
          await tester.pumpAndSettle();
          expect(tester.getSize(find.byKey(const Key('B'))).width, 0);

          controller.show(1);
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final midWidth = tester.getSize(find.byKey(const Key('B'))).width;
          expect(midWidth, greaterThan(0));
          expect(midWidth, lessThan(200));

          await tester.pumpAndSettle();
          expect(tester.getSize(find.byKey(const Key('B'))).width, 200);
        },
      );

      testWidgets(
        'preserves continuity when show is called mid-hide',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            buildHarness(
              controller: controller,
              hideAnimation: const ResizableHideAnimation(),
            ),
          );
          await tester.pumpAndSettle();

          controller.hide(1);
          // Two pumps to seed the Ticker, then advance halfway.
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final widthBeforeShow =
              tester.getSize(find.byKey(const Key('B'))).width;
          expect(widthBeforeShow, greaterThan(0));
          expect(widthBeforeShow, lessThan(200));

          controller.show(1);
          await tester.pump();

          final widthAfterShow =
              tester.getSize(find.byKey(const Key('B'))).width;
          // The first frame after `show` should mirror the from-snapshot,
          // i.e. the displayed width at the moment `show` was called.
          expect(
            widthAfterShow,
            closeTo(widthBeforeShow, 1.0),
          );
        },
      );

      testWidgets(
        'cancels the animation when available space changes mid-flight',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            buildHarness(
              controller: controller,
              hideAnimation: const ResizableHideAnimation(),
            ),
          );
          await tester.pumpAndSettle();

          controller.hide(1);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          await tester.binding.setSurfaceSize(const Size(800, 400));
          await tester.pumpAndSettle();

          // After the resize, the hidden child still has zero width and the
          // remaining children absorb the new available space.
          expect(tester.getSize(find.byKey(const Key('B'))).width, 0);
          final aWidth = tester.getSize(find.byKey(const Key('A'))).width;
          final cWidth = tester.getSize(find.byKey(const Key('C'))).width;
          expect(aWidth, 200);
          expect(cWidth, equals(800 - aWidth));
        },
      );

      testWidgets(
        'leaves no pending timers when disposed mid-flight',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            buildHarness(
              controller: controller,
              hideAnimation: const ResizableHideAnimation(),
            ),
          );
          await tester.pumpAndSettle();

          controller.hide(1);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          // Replace the harness with an empty widget — the previous
          // container's State is disposed.
          await tester.pumpWidget(const SizedBox());
          await tester.pump();

          expect(tester.binding.transientCallbackCount, 0);
        },
      );

      testWidgets(
        'controller.isHidden reflects the intent immediately',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            buildHarness(
              controller: controller,
              hideAnimation: const ResizableHideAnimation(),
            ),
          );
          await tester.pumpAndSettle();

          controller.hide(0);
          // Without any pump, the controller's reported intent is already
          // hidden, even though the visual transition has not begun.
          expect(controller.isHidden(0), isTrue);

          await tester.pumpAndSettle();
        },
      );

      testWidgets(
        'batches consecutive hides into a single animation',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            buildHarness(
              controller: controller,
              hideAnimation: const ResizableHideAnimation(),
            ),
          );
          await tester.pumpAndSettle();

          controller.hide(0);
          controller.hide(1);
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          // Both children interpolate inside the same animation — at the
          // halfway mark each width is strictly between its start and 0.
          final aWidth = tester.getSize(find.byKey(const Key('A'))).width;
          final bWidth = tester.getSize(find.byKey(const Key('B'))).width;
          expect(aWidth, greaterThan(0));
          expect(aWidth, lessThan(200));
          expect(bWidth, greaterThan(0));
          expect(bWidth, lessThan(200));

          await tester.pumpAndSettle();
          expect(tester.getSize(find.byKey(const Key('A'))).width, 0);
          expect(tester.getSize(find.byKey(const Key('B'))).width, 0);
        },
      );

      testWidgets(
        'disposes the animation controller when hideAnimation is removed '
        'mid-flight',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          Widget appWithAnimation(ResizableHideAnimation? animation) {
            return MaterialApp(
              home: Scaffold(
                body: ResizableContainer(
                  controller: controller,
                  direction: Axis.horizontal,
                  hideAnimation: animation,
                  children: const [
                    ResizableChild(
                      size: ResizableSize.pixels(200),
                      divider: ResizableDivider(thickness: 2),
                      child: SizedBox.expand(key: Key('A')),
                    ),
                    ResizableChild(
                      size: ResizableSize.pixels(200),
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
            );
          }

          await tester.pumpWidget(
            appWithAnimation(const ResizableHideAnimation()),
          );
          await tester.pumpAndSettle();

          controller.hide(1);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          // Remove the animation config while the tween is still running.
          await tester.pumpWidget(appWithAnimation(null));
          await tester.pump();

          // The hidden child snaps to its target (0) and no pending animation
          // timers remain.
          expect(tester.getSize(find.byKey(const Key('B'))).width, 0);
          expect(tester.binding.transientCallbackCount, 0);
        },
      );

      testWidgets(
        'animates the next hide after hideAnimation switches on',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          Widget appWithAnimation(ResizableHideAnimation? animation) {
            return MaterialApp(
              home: Scaffold(
                body: ResizableContainer(
                  controller: controller,
                  direction: Axis.horizontal,
                  hideAnimation: animation,
                  children: const [
                    ResizableChild(
                      size: ResizableSize.pixels(200),
                      divider: ResizableDivider(thickness: 2),
                      child: SizedBox.expand(key: Key('A')),
                    ),
                    ResizableChild(
                      size: ResizableSize.pixels(200),
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
            );
          }

          await tester.pumpWidget(appWithAnimation(null));
          await tester.pumpAndSettle();

          // Switch animation on after first build.
          await tester.pumpWidget(
            appWithAnimation(const ResizableHideAnimation()),
          );
          await tester.pumpAndSettle();

          controller.hide(1);
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final midWidth = tester.getSize(find.byKey(const Key('B'))).width;
          expect(midWidth, greaterThan(0));
          expect(midWidth, lessThan(200));
        },
      );

      testWidgets(
        'controller.pixels reports the target value after hide',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            buildHarness(
              controller: controller,
              hideAnimation: const ResizableHideAnimation(),
            ),
          );
          await tester.pumpAndSettle();

          controller.hide(0);
          await tester.pump();

          // The container has captured the target via the offstage layout
          // and pushed it into the controller — so pixels[0] is 0 well
          // before the visible transition finishes.
          expect(controller.pixels[0], 0);

          await tester.pumpAndSettle();
        },
      );
    });

    group('controller swap', () {
      Widget buildApp(ResizableController? controller) {
        return MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              controller: controller,
              direction: Axis.horizontal,
              children: const [
                ResizableChild(
                  divider: ResizableDivider(thickness: 2),
                  size: ResizableSize.ratio(0.5),
                  child: SizedBox.expand(key: Key('A')),
                ),
                ResizableChild(
                  size: ResizableSize.ratio(0.5),
                  child: SizedBox.expand(key: Key('B')),
                ),
              ],
            ),
          ),
        );
      }

      testWidgets('rebinds when a new controller is supplied', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1000));
        final first = ResizableController();
        addTearDown(first.dispose);
        final second = ResizableController();
        addTearDown(second.dispose);

        await tester.pumpWidget(buildApp(first));
        await tester.pumpAndSettle();

        await tester.pumpWidget(buildApp(second));
        await tester.pumpAndSettle();

        // The new controller drives the container.
        second.setSizes(const [
          ResizableSize.ratio(0.8),
          ResizableSize.ratio(0.2),
        ]);
        await tester.pump();

        const available = 1000 - 2;
        expect(
          tester.getSize(find.byKey(const Key('A'))).width,
          available * 0.8,
        );

        // The old controller is detached — mutating it does not affect layout.
        first.setSizes(const [
          ResizableSize.ratio(0.1),
          ResizableSize.ratio(0.9),
        ]);
        await tester.pump();

        expect(
          tester.getSize(find.byKey(const Key('A'))).width,
          available * 0.8,
        );
      });

      testWidgets(
        'disposes the internal default when swapped to an external controller',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(1000, 1000));

          await tester.pumpWidget(buildApp(null));
          await tester.pumpAndSettle();

          final external = ResizableController();
          addTearDown(external.dispose);

          await tester.pumpWidget(buildApp(external));
          await tester.pumpAndSettle();

          // The new external controller is functional after the swap.
          external.setSizes(const [
            ResizableSize.ratio(0.3),
            ResizableSize.ratio(0.7),
          ]);
          await tester.pump();

          const available = 1000 - 2;
          expect(
            tester.getSize(find.byKey(const Key('A'))).width,
            available * 0.3,
          );
        },
      );

      testWidgets(
        'creates a fresh default when swapped from external to null',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(1000, 1000));
          final external = ResizableController();
          addTearDown(external.dispose);

          await tester.pumpWidget(buildApp(external));
          await tester.pumpAndSettle();

          await tester.pumpWidget(buildApp(null));
          await tester.pumpAndSettle();

          // Mutating the now-detached external controller has no effect.
          external.setSizes(const [
            ResizableSize.ratio(0.9),
            ResizableSize.ratio(0.1),
          ]);
          await tester.pump();

          const available = 1000 - 2;
          expect(
            tester.getSize(find.byKey(const Key('A'))).width,
            available * 0.5,
          );
        },
      );
    });

    group('notify count', () {
      // The main controller listener is reserved for structural changes
      // (children list, declared sizes, hidden set). Build-path swaps
      // between the cold and live paths are signalled via
      // `needsLayoutListenable` instead. These tests pin the resulting
      // notification counts so a future refactor cannot silently
      // re-introduce a redundant notify cycle on the main listener.
      testWidgets('initial mount fires no main listener', (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 400));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        var mainNotifies = 0;
        var needsLayoutNotifies = 0;
        controller.addListener(() => mainNotifies++);
        controller.needsLayoutListenable.addListener(
          () => needsLayoutNotifies++,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                controller: controller,
                direction: Axis.horizontal,
                children: const [
                  ResizableChild(
                    size: ResizableSize.expand(),
                    child: SizedBox.expand(key: Key('A')),
                  ),
                  ResizableChild(
                    size: ResizableSize.pixels(200),
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
        );
        await tester.pumpAndSettle();

        // Main listener: no structural changes after mount, so zero fires.
        expect(mainNotifies, 0);
        // needsLayoutListenable: true on the first available-space call,
        // false on the post-frame setRenderedSizes that completes the cold
        // layout. The container observes this to swap to the live path.
        expect(needsLayoutNotifies, 2);
      });

      testWidgets('hide fires the main listener once', (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 400));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                controller: controller,
                direction: Axis.horizontal,
                children: const [
                  ResizableChild(
                    size: ResizableSize.expand(),
                    child: SizedBox.expand(key: Key('A')),
                  ),
                  ResizableChild(
                    size: ResizableSize.pixels(200),
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
        );
        await tester.pumpAndSettle();

        var mainNotifies = 0;
        var needsLayoutNotifies = 0;
        controller.addListener(() => mainNotifies++);
        controller.needsLayoutListenable.addListener(
          () => needsLayoutNotifies++,
        );

        controller.hide(1);
        await tester.pumpAndSettle();

        // Main listener: exactly one fire from the structural hide change.
        expect(mainNotifies, 1);
        // needsLayoutListenable: true from setHidden invalidating layout,
        // false from the post-frame setRenderedSizes completing the
        // subsequent cold layout.
        expect(needsLayoutNotifies, 2);
      });
    });

    group('resizable', () {
      testWidgets(
        'locks every divider when false',
        (tester) async {
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.binding.setSurfaceSize(const Size(600, 100));
          addTearDown(() async => await tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ResizableContainer(
                  controller: controller,
                  direction: Axis.horizontal,
                  resizable: false,
                  children: const [
                    ResizableChild(
                      size: ResizableSize.ratio(0.33),
                      child: SizedBox.expand(),
                    ),
                    ResizableChild(
                      size: ResizableSize.ratio(0.33),
                      child: SizedBox.expand(),
                    ),
                    ResizableChild(
                      size: ResizableSize.ratio(0.34),
                      child: SizedBox.expand(),
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final beforeSizes = List<double>.of(controller.pixels);
          final dividers = find.byType(ResizableContainerDivider);
          expect(dividers, findsNWidgets(2));

          await tester.drag(dividers.first, const Offset(80, 0));
          await tester.pumpAndSettle();
          await tester.drag(dividers.last, const Offset(-80, 0));
          await tester.pumpAndSettle();

          expect(controller.pixels, beforeSizes);
        },
      );

      testWidgets(
        'programmatic resize still works when false',
        (tester) async {
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.binding.setSurfaceSize(const Size(600, 100));
          addTearDown(() async => await tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ResizableContainer(
                  controller: controller,
                  direction: Axis.horizontal,
                  resizable: false,
                  children: const [
                    ResizableChild(
                      size: ResizableSize.ratio(0.5),
                      child: SizedBox.expand(),
                    ),
                    ResizableChild(
                      size: ResizableSize.ratio(0.5),
                      child: SizedBox.expand(),
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          controller.setSizes(const [
            ResizableSize.ratio(0.25),
            ResizableSize.ratio(0.75),
          ]);
          await tester.pumpAndSettle();

          const available = 600 - 1;
          expect(controller.pixels[0], closeTo(available * 0.25, 0.001));
          expect(controller.pixels[1], closeTo(available * 0.75, 0.001));
        },
      );
    });
  });
}

class _ToggleChildApp extends StatefulWidget {
  const _ToggleChildApp();

  @override
  State<_ToggleChildApp> createState() => __ToggleChildAppState();
}

class __ToggleChildAppState extends State<_ToggleChildApp> {
  bool hidden = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: [
            Switch(
              key: const Key('ToggleSwitch'),
              value: hidden,
              onChanged: (_) => setState(() => hidden = !hidden),
            ),
          ],
        ),
        body: ResizableContainer(
          direction: Axis.horizontal,
          children: [
            const ResizableChild(
              divider: ResizableDivider(
                thickness: 2,
              ),
              size: ResizableSize.expand(flex: 2),
              child: SizedBox.expand(
                key: Key('ChildA'),
              ),
            ),
            if (!hidden)
              const ResizableChild(
                size: ResizableSize.expand(),
                child: SizedBox.expand(
                  key: Key('ChildB'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

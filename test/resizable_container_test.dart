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

    group('expand sizing with constraints', () {
      Future<List<double>> pumpExpands(
        WidgetTester tester, {
        required double expandSpace,
        required List<ResizableSize> sizes,
      }) async {
        final dividerSpace = (sizes.length - 1).toDouble();
        await tester.binding.setSurfaceSize(
          Size(expandSpace + dividerSpace, 1000),
        );
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                direction: Axis.horizontal,
                children: [
                  for (var i = 0; i < sizes.length; i++)
                    ResizableChild(
                      size: sizes[i],
                      child: SizedBox.expand(key: Key('Box$i')),
                    ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        return [
          for (var i = 0; i < sizes.length; i++)
            tester.getSize(find.byKey(Key('Box$i'))).width,
        ];
      }

      testWidgets('splits by flex when nothing is constrained', (tester) async {
        final widths = await pumpExpands(
          tester,
          expandSpace: 400,
          sizes: const [
            ResizableSize.expand(flex: 1),
            ResizableSize.expand(flex: 3),
          ],
        );

        expect(widths, equals([100, 300]));
      });

      testWidgets('recomputes shares after a max violation', (tester) async {
        final widths = await pumpExpands(
          tester,
          expandSpace: 400,
          sizes: const [
            ResizableSize.expand(flex: 1, max: 50),
            ResizableSize.expand(flex: 1),
            ResizableSize.expand(flex: 2),
          ],
        );

        expect(widths[0], equals(50));
        expect(widths[1], moreOrLessEquals(350 / 3));
        expect(widths[2], moreOrLessEquals(700 / 3));
      });

      testWidgets('recomputes shares after a min violation', (tester) async {
        final widths = await pumpExpands(
          tester,
          expandSpace: 400,
          sizes: const [
            ResizableSize.expand(flex: 1, min: 200),
            ResizableSize.expand(flex: 1),
            ResizableSize.expand(flex: 2),
          ],
        );

        expect(widths[0], equals(200));
        expect(widths[1], moreOrLessEquals(200 / 3));
        expect(widths[2], moreOrLessEquals(400 / 3));
      });

      testWidgets('freezes only the net violation direction', (tester) async {
        final widths = await pumpExpands(
          tester,
          expandSpace: 488,
          sizes: const [
            ResizableSize.expand(flex: 3, max: 145),
            ResizableSize.expand(flex: 3, min: 283),
            ResizableSize.expand(flex: 2, max: 196),
          ],
        );

        expect(widths, equals([123, 283, 82]));
      });

      testWidgets('ends at the minimums when space is too small',
          (tester) async {
        final widths = await pumpExpands(
          tester,
          expandSpace: 100,
          sizes: const [
            ResizableSize.expand(flex: 1, min: 80),
            ResizableSize.expand(flex: 1, min: 60),
          ],
        );

        expect(tester.takeException(), isNull);
        expect(widths, equals([80, 60]));
      });

      testWidgets('lays out without hanging in an unbounded main axis',
          (tester) async {
        final errors = <FlutterErrorDetails>[];
        final originalOnError = FlutterError.onError;
        FlutterError.onError = errors.add;

        try {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ResizableContainer(
                    direction: Axis.horizontal,
                    children: [
                      ResizableChild(child: SizedBox.expand()),
                      ResizableChild(child: SizedBox.expand()),
                    ],
                  ),
                ),
              ),
            ),
          );
        } finally {
          FlutterError.onError = originalOnError;
        }

        expect(errors, isNotEmpty);
        expect(
          errors.first.exceptionAsString(),
          contains('was given unbounded width'),
        );
      });
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

    testWidgets('fires drag events and resizes in a vertical container',
        (tester) async {
      var dragStart = false;
      var dragEnd = false;

      await tester.binding.setSurfaceSize(const Size(1000, 1000));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              direction: Axis.vertical,
              children: [
                ResizableChild(
                  divider: ResizableDivider(
                    onDragStart: () => dragStart = true,
                    onDragEnd: () => dragEnd = true,
                  ),
                  size: ResizableSize.pixels(200),
                  child: SizedBox.expand(key: Key('BoxA')),
                ),
                ResizableChild(
                  size: ResizableSize.expand(),
                  child: SizedBox.expand(key: Key('BoxB')),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final heightBefore = tester.getSize(find.byKey(Key('BoxA'))).height;

      final divider = find.byType(ResizableContainerDivider);
      await tester.drag(divider, Offset(0, 50 + kDragSlopDefault));
      await tester.pumpAndSettle();

      final heightAfter = tester.getSize(find.byKey(Key('BoxA'))).height;

      expect(heightAfter, greaterThan(heightBefore));
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

      void expectDividersCollapsed(WidgetTester tester) {
        final dividers = find.byType(ResizableContainerDivider);
        expect(dividers, findsNWidgets(2));
        for (var i = 0; i < 2; i++) {
          expect(tester.getSize(dividers.at(i)).width, 0);
        }
        expect(dividers.hitTestable(), findsNothing);
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
          // Both dividers adjacent to the hidden child collapse to zero.
          expectDividersCollapsed(tester);
        },
      );

      testWidgets(
        'keeps a dragged sibling size across hide and show',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          addTearDown(() async => await tester.binding.setSurfaceSize(null));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(buildHarness(controller: controller));
          await tester.pumpAndSettle();

          await tester.drag(
            find.byType(ResizableContainerDivider).last,
            const Offset(kDragSlopDefault + 30, 0),
          );
          await tester.pumpAndSettle();

          double widthOf(String key) =>
              tester.getSize(find.byKey(Key(key))).width;

          expect(widthOf('B'), 230);

          controller.hide(0);
          await tester.pumpAndSettle();
          controller.show(0);
          await tester.pumpAndSettle();

          expect(widthOf('A'), 200);
          expect(widthOf('B'), 230);
          expect(widthOf('C'), 166);
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
          // pump #1: the animation already started in the hide notification;
          // this frame renders it at t = 0 and schedules the first tick.
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
        'collapses the adjacent divider once the animation settles',
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

          // Both dividers adjacent to the hidden child collapse to zero.
          expectDividersCollapsed(tester);
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

          // The controller redistributes its pixels as soon as it hides, so
          // pixels[0] is 0 well before the visible transition finishes.
          expect(controller.pixels[0], 0);

          await tester.pumpAndSettle();
        },
      );

      testWidgets(
        'finishes the capture phase when a hide is reversed in the same frame',
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

          controller
            ..hide(1)
            ..show(1);
          await tester.pumpAndSettle();

          expect(tester.getSize(find.byKey(const Key('B'))).width, 200);

          controller.hide(1);
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final midWidth = tester.getSize(find.byKey(const Key('B'))).width;
          expect(midWidth, lessThan(200));
          expect(midWidth, greaterThan(0));
        },
      );

      testWidgets(
        'animates from the pre-change pixels after a window resize',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          addTearDown(() async => await tester.binding.setSurfaceSize(null));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            buildHarness(
              controller: controller,
              hideAnimation: const ResizableHideAnimation(),
            ),
          );
          await tester.pumpAndSettle();

          await tester.binding.setSurfaceSize(const Size(800, 400));
          await tester.pumpAndSettle();
          expect(tester.getSize(find.byKey(const Key('C'))).width, 396);

          controller.hide(1);
          await tester.pump();

          expect(tester.getSize(find.byKey(const Key('A'))).width, 200);
          expect(tester.getSize(find.byKey(const Key('B'))).width, 200);
          expect(tester.getSize(find.byKey(const Key('C'))).width, 396);
        },
      );

      testWidgets(
        'a divider drag cancels the running animation',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          addTearDown(() async => await tester.binding.setSurfaceSize(null));
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
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          await tester.drag(
            find.byType(ResizableContainerDivider).last,
            const Offset(kDragSlopDefault + 20, 0),
          );
          await tester.pump();

          double widthOf(String key) =>
              tester.getSize(find.byKey(Key(key))).width;

          expect(widthOf('A'), 0);
          expect(widthOf('B'), controller.pixels[1]);
          expect(widthOf('C'), controller.pixels[2]);
          final widthB = widthOf('B');

          await tester.pumpAndSettle();

          expect(widthOf('B'), widthB);
          expect(widthOf('B'), 220);
        },
      );

      testWidgets(
        'ignores a divider drag during the capture frame',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          addTearDown(() async => await tester.binding.setSurfaceSize(null));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            buildHarness(
              controller: controller,
              hideAnimation: const ResizableHideAnimation(),
            ),
          );
          await tester.pumpAndSettle();

          // setSizes forces a layout pass, so hide takes the capture flow.
          controller.setSizes(const [
            ResizableSize.pixels(200),
            ResizableSize.pixels(200),
            ResizableSize.expand(),
          ]);
          controller.hide(1);
          final before = List.of(controller.pixels);

          final gesture = await tester.startGesture(
            tester.getCenter(find.byType(ResizableContainerDivider).first),
          );
          await gesture.moveBy(const Offset(40, 0));
          await gesture.moveBy(const Offset(10, 0));
          await gesture.up();

          expect(controller.pixels, equals(before));

          await tester.pumpAndSettle();

          expect(tester.getSize(find.byKey(const Key('B'))).width, 0);
          expect(tester.getSize(find.byKey(const Key('C'))).width, 400);
        },
      );

      testWidgets(
        'a hide during a running animation continues from the current sizes',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          addTearDown(() async => await tester.binding.setSurfaceSize(null));
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
          await tester.pump(const Duration(milliseconds: 100));

          final midWidthC = tester.getSize(find.byKey(const Key('C'))).width;
          expect(midWidthC, greaterThan(196));
          expect(midWidthC, lessThan(400));

          controller.hide(0);
          await tester.pump();

          expect(
            tester.getSize(find.byKey(const Key('C'))).width,
            closeTo(midWidthC, 1e-6),
          );

          await tester.pumpAndSettle();

          expect(tester.getSize(find.byKey(const Key('C'))).width, 600);
        },
      );

      testWidgets(
        'show after setSizes while hidden still animates',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(600, 400));
          addTearDown(() async => await tester.binding.setSurfaceSize(null));
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

          controller.setSizes(const [
            ResizableSize.pixels(200),
            ResizableSize.pixels(150),
            ResizableSize.expand(),
          ]);
          controller.show(1);
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final midWidth = tester.getSize(find.byKey(const Key('B'))).width;
          expect(midWidth, greaterThan(0));
          expect(midWidth, lessThan(150));

          await tester.pumpAndSettle();

          expect(tester.getSize(find.byKey(const Key('B'))).width, 150);
        },
      );

      group('showing a shrink child', () {
        Widget buildShrinkHarness(ResizableController controller) {
          return MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                controller: controller,
                direction: Axis.horizontal,
                hideAnimation: const ResizableHideAnimation(),
                children: const [
                  ResizableChild(
                    size: ResizableSize.shrink(),
                    child: SizedBox(key: Key('S'), width: 150),
                  ),
                  ResizableChild(
                    size: ResizableSize.expand(),
                    child: SizedBox.expand(key: Key('E')),
                  ),
                ],
              ),
            ),
          );
        }

        double widthOf(WidgetTester tester, String key) =>
            tester.getSize(find.byKey(Key(key))).width;

        testWidgets(
          'animates back to its natural width',
          (tester) async {
            await tester.binding.setSurfaceSize(const Size(600, 400));
            final controller = ResizableController();
            addTearDown(controller.dispose);

            await tester.pumpWidget(buildShrinkHarness(controller));
            await tester.pumpAndSettle();
            expect(widthOf(tester, 'S'), 150);

            controller.hide(0);
            await tester.pumpAndSettle();
            expect(widthOf(tester, 'S'), 0);

            controller.show(0);
            await tester.pump();
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));

            final midWidth = widthOf(tester, 'S');
            expect(midWidth, greaterThan(0));
            expect(midWidth, lessThan(150));

            await tester.pumpAndSettle();

            expect(widthOf(tester, 'S'), 150);
            expect(controller.pixels[0], 150);
            expect(controller.isHidden(0), isFalse);
          },
        );

        testWidgets(
          'restores the width when the show interrupts the hide animation',
          (tester) async {
            await tester.binding.setSurfaceSize(const Size(600, 400));
            final controller = ResizableController();
            addTearDown(controller.dispose);

            await tester.pumpWidget(buildShrinkHarness(controller));
            await tester.pumpAndSettle();

            controller.hide(0);
            await tester.pump();
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 50));

            controller.show(0);
            await tester.pumpAndSettle();

            expect(widthOf(tester, 'S'), 150);
            expect(controller.pixels[0], 150);
          },
        );

        testWidgets(
          'stays between hidden and full width when the show interrupts the '
          'hide animation',
          (tester) async {
            await tester.binding.setSurfaceSize(const Size(600, 400));
            final controller = ResizableController();
            addTearDown(controller.dispose);

            await tester.pumpWidget(buildShrinkHarness(controller));
            await tester.pumpAndSettle();

            controller.hide(0);
            await tester.pump();
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));

            controller.show(0);
            await tester.pump();

            final width = widthOf(tester, 'S');
            expect(width, greaterThan(0));
            expect(width, lessThan(150));

            await tester.pumpAndSettle();
          },
        );

        testWidgets(
          'restores every shrink child shown before the capture completes',
          (tester) async {
            await tester.binding.setSurfaceSize(const Size(600, 400));
            final controller = ResizableController();
            addTearDown(controller.dispose);

            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: ResizableContainer(
                    controller: controller,
                    direction: Axis.horizontal,
                    hideAnimation: const ResizableHideAnimation(),
                    children: const [
                      ResizableChild(
                        size: ResizableSize.shrink(),
                        child: SizedBox(key: Key('S1'), width: 150),
                      ),
                      ResizableChild(
                        size: ResizableSize.shrink(),
                        child: SizedBox(key: Key('S2'), width: 90),
                      ),
                      ResizableChild(
                        size: ResizableSize.expand(),
                        child: SizedBox.expand(),
                      ),
                    ],
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            controller
              ..hide(0)
              ..hide(1);
            await tester.pumpAndSettle();

            controller
              ..show(0)
              ..show(1);
            await tester.pumpAndSettle();

            expect(widthOf(tester, 'S1'), 150);
            expect(widthOf(tester, 'S2'), 90);
            expect(controller.pixels.take(2), [150, 90]);
          },
        );

        testWidgets(
          'restores the width without a hideAnimation',
          (tester) async {
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
                        size: ResizableSize.shrink(),
                        child: SizedBox(key: Key('S'), width: 150),
                      ),
                      ResizableChild(
                        size: ResizableSize.expand(),
                        child: SizedBox.expand(),
                      ),
                    ],
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            controller.hide(0);
            await tester.pumpAndSettle();
            controller.show(0);
            await tester.pumpAndSettle();

            expect(widthOf(tester, 'S'), 150);
          },
        );

        testWidgets(
          'does not throw when children shrink while the last is hidden',
          (tester) async {
            await tester.binding.setSurfaceSize(const Size(600, 400));
            final controller = ResizableController();
            addTearDown(controller.dispose);

            Widget build(List<ResizableChild> children) {
              return MaterialApp(
                home: Scaffold(
                  body: ResizableContainer(
                    controller: controller,
                    direction: Axis.horizontal,
                    hideAnimation: const ResizableHideAnimation(),
                    children: children,
                  ),
                ),
              );
            }

            await tester.pumpWidget(
              build(const [
                ResizableChild(
                  size: ResizableSize.expand(),
                  child: SizedBox.expand(),
                ),
                ResizableChild(
                  size: ResizableSize.shrink(),
                  child: SizedBox(width: 150),
                ),
              ]),
            );
            await tester.pumpAndSettle();

            controller.hide(1);
            await tester.pumpAndSettle();

            await tester.pumpWidget(
              build(const [
                ResizableChild(
                  size: ResizableSize.expand(),
                  child: SizedBox.expand(),
                ),
              ]),
            );
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);
            expect(controller.pixels, hasLength(1));
          },
        );

        testWidgets(
          'skips the animation when the size changed while hidden',
          (tester) async {
            await tester.binding.setSurfaceSize(const Size(600, 400));
            final controller = ResizableController();
            addTearDown(controller.dispose);

            await tester.pumpWidget(buildShrinkHarness(controller));
            await tester.pumpAndSettle();

            controller.hide(0);
            await tester.pumpAndSettle();

            controller.setSizes(const [
              ResizableSize.shrink(max: 100),
              ResizableSize.expand(),
            ]);
            controller.show(0);
            await tester.pump();

            expect(widthOf(tester, 'S'), 100);

            await tester.pumpAndSettle();

            expect(widthOf(tester, 'S'), 100);
            expect(controller.pixels[0], 100);
          },
        );
      });
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

      testWidgets('keeps matching state when a used controller is swapped in',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1000));
        final first = ResizableController();
        addTearDown(first.dispose);
        final used = ResizableController();
        addTearDown(used.dispose);

        await tester.pumpWidget(buildApp(used));
        await tester.pumpAndSettle();
        used.hide(1);
        await tester.pumpAndSettle();
        final widthBefore = tester.getSize(find.byKey(const Key('A'))).width;

        await tester.pumpWidget(buildApp(first));
        await tester.pumpAndSettle();
        await tester.pumpWidget(buildApp(used));
        await tester.pumpAndSettle();

        expect(used.hiddenIndices, {1});
        expect(
          tester.getSize(find.byKey(const Key('A'))).width,
          closeTo(widthBefore, 0.01),
        );
      });

      testWidgets('lays out again when the direction changes with a swap',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1000));
        final first = ResizableController();
        addTearDown(first.dispose);
        final second = ResizableController();
        addTearDown(second.dispose);

        await tester.pumpWidget(
            _DirectionSwapApp(controller: first, direction: Axis.horizontal));
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(ResizableContainerDivider),
          const Offset(200, 0),
        );
        await tester.pumpAndSettle();
        expect(first.pixels[0], greaterThan(600));

        await tester.pumpWidget(
            _DirectionSwapApp(controller: second, direction: Axis.horizontal));
        await tester.pumpAndSettle();

        await tester.pumpWidget(
            _DirectionSwapApp(controller: first, direction: Axis.vertical));
        await tester.pumpAndSettle();

        final size = tester.getSize(find.byKey(const Key('A')));
        expect(size.width, closeTo(1000, 0.01));
        expect(size.height, closeTo(499.5, 0.01));
      });

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
      // The container schedules a post-frame setRenderedSizes after every
      // layout pass. That callback notifies controller listeners so the
      // build path can switch from the layout widget (with placeholder
      // dividers) to the flex widget (with interactive dividers). These
      // tests pin the resulting notification count so a future refactor
      // can't silently introduce another redundant notify cycle.
      testWidgets('initial mount notifies exactly once', (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 400));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        var notifies = 0;
        controller.addListener(() => notifies++);

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

        // Exactly one notify: the post-frame setRenderedSizes that
        // populates controller.pixels and switches the build path.
        expect(notifies, 1);
      });

      testWidgets('hide produces exactly one notify', (tester) async {
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

        var notifies = 0;
        controller.addListener(() => notifies++);

        controller.hide(1);
        await tester.pumpAndSettle();

        // Pixels are already valid, so hiding redistributes them in place
        // and no layout pass follows.
        expect(notifies, 1);
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

    group('repaint isolation', () {
      late List<int> builds;
      late List<_CountingPainter> painters;

      setUp(() {
        builds = [0, 0, 0];
        painters = [_CountingPainter(), _CountingPainter(), _CountingPainter()];
      });

      Future<void> pumpThreePanes(WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                direction: Axis.horizontal,
                children: [
                  for (var i = 0; i < 3; i++)
                    ResizableChild(
                      child: Builder(
                        builder: (_) {
                          builds[i]++;
                          return CustomPaint(
                            painter: painters[i],
                            child: const SizedBox.expand(),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> dragFirstDivider(WidgetTester tester) async {
        final divider = find.byType(ResizableContainerDivider).first;
        final gesture = await tester.startGesture(tester.getCenter(divider));
        await gesture.moveBy(const Offset(kDragSlopDefault + 1, 0));
        await tester.pump();
        for (var i = 0; i < 20; i++) {
          await gesture.moveBy(const Offset(5, 0));
          await tester.pump();
        }
        await gesture.up();
        await tester.pump();
      }

      testWidgets('does not repaint panes whose size did not change',
          (tester) async {
        await pumpThreePanes(tester);
        final paintsBefore = painters.map((p) => p.paints).toList();

        await dragFirstDivider(tester);

        expect(painters[0].paints - paintsBefore[0], greaterThan(0));
        expect(painters[1].paints - paintsBefore[1], greaterThan(0));
        expect(
          painters[2].paints - paintsBefore[2],
          0,
          reason: 'pane 2 did not resize, so its RepaintBoundary should '
              'isolate it from the drag',
        );
      });

      testWidgets('does not rebuild user children', (tester) async {
        await pumpThreePanes(tester);
        final buildsBefore = [...builds];

        await dragFirstDivider(tester);

        for (var i = 0; i < builds.length; i++) {
          expect(builds[i] - buildsBefore[i], 0, reason: 'pane $i');
        }
      });
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

class _CountingPainter extends CustomPainter {
  int paints = 0;

  @override
  void paint(Canvas canvas, Size size) => paints++;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DirectionSwapApp extends StatelessWidget {
  const _DirectionSwapApp({required this.controller, required this.direction});

  final ResizableController controller;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ResizableContainer(
          controller: controller,
          direction: direction,
          children: const [
            ResizableChild(
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
}

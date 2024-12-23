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
        expect(boxBSize.width, equals(200));
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
        expect(boxBSize.width, equals(400));
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
        moreOrLessEquals((1000 - 2) * 2 / 3),
      );
      expect(
        tester.getSize(find.byKey(const Key('ChildB'))).width,
        moreOrLessEquals((1000 - 2) * 1 / 3),
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
                      size: ResizableSize.shrink(),
                      child: SizedBox(
                        width: 200,
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

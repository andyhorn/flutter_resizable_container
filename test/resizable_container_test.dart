import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(ResizableContainer, () {
    testWidgets(
      'throws an error if the child ratios are greater than 1',
      (tester) async {
        expect(
          () async => await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ResizableContainer(
                  controller: ResizableController(
                    data: const [
                      ResizableChildData(
                        startingRatio: 0.5,
                      ),
                      ResizableChildData(
                        startingRatio: 0.6,
                      ),
                    ],
                  ),
                  direction: Axis.horizontal,
                  children: const [
                    SizedBox.shrink(),
                    SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),
          throwsArgumentError,
        );
      },
    );

    testWidgets(
      'throws an error if the children and data are of different lengths',
      (widgetTester) async {
        final controller = ResizableController(
          data: const [
            ResizableChildData(),
            ResizableChildData(),
            ResizableChildData(),
          ],
        );

        expect(
          () async => await widgetTester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ResizableContainer(
                  controller: controller,
                  direction: Axis.horizontal,
                  children: const [
                    SizedBox.shrink(),
                    SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),
          throwsAssertionError,
        );
      },
    );

    testWidgets('can resize by dragging divider', (tester) async {
      const dividerWidth = 2.0;
      final controller = ResizableController(
        data: const [
          ResizableChildData(
            startingRatio: 0.5,
          ),
          ResizableChildData(
            startingRatio: 0.5,
          ),
        ],
      );

      await tester.binding.setSurfaceSize(const Size(1000, 1000));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              controller: controller,
              direction: Axis.horizontal,
              divider: const ResizableDivider(
                size: dividerWidth,
              ),
              children: const [
                SizedBox.expand(
                  key: Key('BoxA'),
                ),
                SizedBox.expand(
                  key: Key('BoxB'),
                ),
              ],
            ),
          ),
        ),
      );

      final resizableContainer = tester.widget(find.byType(ResizableContainer));
      expect(resizableContainer, isNotNull);

      final handle = find.byType(ResizableContainerDivider).first;
      expect(handle, isNotNull);

      await tester.drag(handle, const Offset(100, 0));
      await tester.pump();

      expect(controller.ratios.map((r) => (r * 10).round()), [6, 4]);

      final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
      final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));

      expect(boxASize.width, equals(controller.sizes.first));
      expect(boxBSize.width, equals(controller.sizes.last));
    });

    testWidgets('can resize using the controller', (tester) async {
      const dividerWidth = 2.0;
      final controller = ResizableController(
        data: const [
          ResizableChildData(
            startingRatio: 0.5,
          ),
          ResizableChildData(
            startingRatio: 0.5,
          ),
        ],
      );

      await tester.binding.setSurfaceSize(const Size(1000, 1000));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              controller: controller,
              direction: Axis.horizontal,
              divider: const ResizableDivider(
                size: dividerWidth,
              ),
              children: const [
                SizedBox.expand(
                  key: Key('BoxA'),
                ),
                SizedBox.expand(
                  key: Key('BoxB'),
                ),
              ],
            ),
          ),
        ),
      );

      const availableSpace = 1000 - dividerWidth;

      final resizableContainer = tester.widget(find.byType(ResizableContainer));
      expect(resizableContainer, isNotNull);

      controller.ratios = [0.6, 0.4];
      await tester.pump();

      final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
      final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));

      // The sizes are not exactly their ratio because the divider width is 2.0
      expect(boxASize, const Size(availableSpace * 0.6, 1000));
      expect(boxBSize, const Size(availableSpace * 0.4, 1000));
    });

    testWidgets('container respects min size', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1000));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              controller: ResizableController(
                data: const [
                  ResizableChildData(
                    startingRatio: 0.5,
                    minSize: 200,
                  ),
                  ResizableChildData(
                    startingRatio: 0.5,
                  ),
                ],
              ),
              direction: Axis.horizontal,
              children: const [
                SizedBox.expand(
                  key: Key('BoxA'),
                ),
                SizedBox.expand(),
              ],
            ),
          ),
        ),
      );

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
        MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              controller: ResizableController(
                data: const [
                  ResizableChildData(
                    startingRatio: 0.5,
                    maxSize: 700,
                  ),
                  ResizableChildData(
                    startingRatio: 0.5,
                  ),
                ],
              ),
              divider: const ResizableDivider(
                size: dividerWidth,
              ),
              direction: Axis.horizontal,
              children: const [
                SizedBox.expand(
                  key: Key('BoxA'),
                ),
                SizedBox.expand(
                  key: Key('BoxB'),
                ),
              ],
            ),
          ),
        ),
      );

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
        MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              controller: ResizableController(
                data: const [
                  ResizableChildData(
                    startingRatio: 0.5,
                    minSize: 200,
                  ),
                  ResizableChildData(
                    startingRatio: 0.5,
                  ),
                ],
              ),
              divider: const ResizableDivider(
                size: dividerWidth,
              ),
              direction: Axis.horizontal,
              children: const [
                SizedBox.expand(
                  key: Key('BoxA'),
                ),
                SizedBox.expand(
                  key: Key('BoxB'),
                ),
              ],
            ),
          ),
        ),
      );

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

    testWidgets(
      'null starting ratios are allotted space evenly',
      (widgetTester) async {
        await widgetTester.binding.setSurfaceSize(
          const Size(1000, 1000),
        );

        final controller = ResizableController(
          data: const [
            ResizableChildData(
              startingRatio: 0.5,
            ),
            ResizableChildData(),
            ResizableChildData(),
          ],
        );

        final container = ResizableContainer(
          controller: controller,
          direction: Axis.horizontal,
          divider: const ResizableDivider(
            size: 2.0,
          ),
          children: const [
            SizedBox.expand(
              key: Key('Box A'),
            ),
            SizedBox.expand(
              key: Key('Box B'),
            ),
            SizedBox.expand(
              key: Key('Box C'),
            ),
          ],
        );

        await widgetTester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: container,
            ),
          ),
        );

        final boxAFinder = find.byKey(const Key('Box A'));
        final boxBFinder = find.byKey(const Key('Box B'));
        final boxCFinder = find.byKey(const Key('Box C'));

        final boxASize = widgetTester.getSize(boxAFinder);
        final boxBSize = widgetTester.getSize(boxBFinder);
        final boxCSize = widgetTester.getSize(boxCFinder);

        // slightly less than 500, 250, and 250 because of the space
        // used by the dividers.
        expect(boxASize, equals(const Size(498, 1000)));
        expect(boxBSize, equals(const Size(249, 1000)));
        expect(boxCSize, equals(const Size(249, 1000)));
      },
    );
  });
}

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
              dividerWidth: dividerWidth,
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
      await tester.pumpAndSettle();

      expect(controller.ratios.map((r) => (r * 10).round()), [6, 4]);

      final boxASize = tester.getSize(find.byKey(const Key('BoxA')));
      final boxBSize = tester.getSize(find.byKey(const Key('BoxB')));

      // The size is not exactly 600 because the divider width is 2.0
      expect(boxASize, const Size(600 - (dividerWidth / 2), 1000));
      expect(boxBSize, const Size(400 - (dividerWidth / 2), 1000));
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
              dividerWidth: dividerWidth,
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
      expect(controller.availableSpace, availableSpace);

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
              dividerWidth: dividerWidth,
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
              dividerWidth: dividerWidth,
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
        const dividerWidth = 2.0;
        const containerWidth = 1000.0;

        await widgetTester.binding.setSurfaceSize(
          const Size(containerWidth, 1000),
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
          dividerWidth: dividerWidth,
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

        final dividerSpace = dividerWidth * (controller.numChildren - 1);
        final availableWidth = containerWidth - dividerSpace;

        final boxAFinder = find.byKey(const Key('Box A'));
        final boxBFinder = find.byKey(const Key('Box B'));
        final boxCFinder = find.byKey(const Key('Box C'));

        final boxASize = widgetTester.getSize(boxAFinder);
        final boxBSize = widgetTester.getSize(boxBFinder);
        final boxCSize = widgetTester.getSize(boxCFinder);

        expect(boxASize, equals(Size(availableWidth * 0.5, 1000)));
        expect(boxBSize, equals(Size(availableWidth * 0.25, 1000)));
        expect(boxCSize, equals(Size(availableWidth * 0.25, 1000)));
      },
    );
  });
}

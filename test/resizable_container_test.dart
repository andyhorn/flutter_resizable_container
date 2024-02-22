import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(ResizableContainer, () {
    testWidgets('throws an error if the child ratios do not equal 1',
        (tester) async {
      expect(
        () async => await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                children: const [
                  ResizableChildData(
                    startingRatio: 0.5,
                    child: SizedBox.shrink(),
                  ),
                  ResizableChildData(
                    startingRatio: 0.6,
                    child: SizedBox.shrink(),
                  ),
                ],
                direction: Axis.horizontal,
              ),
            ),
          ),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('can be created with a controller', (tester) async {
      final controller = ResizableController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              children: const [
                ResizableChildData(
                  startingRatio: 0.5,
                  child: SizedBox.shrink(),
                ),
                ResizableChildData(
                  startingRatio: 0.5,
                  child: SizedBox.shrink(),
                ),
              ],
              direction: Axis.horizontal,
              controller: controller,
            ),
          ),
        ),
      );

      final resizableContainer = tester.widget(find.byType(ResizableContainer));
      expect(resizableContainer, isNotNull);
    });

    testWidgets('can be created without a controller', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              children: const [
                ResizableChildData(
                  startingRatio: 0.5,
                  child: SizedBox.shrink(),
                ),
                ResizableChildData(
                  startingRatio: 0.5,
                  child: SizedBox.shrink(),
                ),
              ],
              direction: Axis.horizontal,
            ),
          ),
        ),
      );

      final resizableContainer = tester.widget(find.byType(ResizableContainer));
      expect(resizableContainer, isNotNull);
    });

    testWidgets('can resize by dragging divider', (tester) async {
      const dividerWidth = 2.0;
      final controller = ResizableController();
      await tester.binding.setSurfaceSize(const Size(1000, 1000));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              dividerWidth: dividerWidth,
              children: const [
                ResizableChildData(
                  startingRatio: 0.5,
                  child: SizedBox.expand(
                    key: Key('BoxA'),
                  ),
                ),
                ResizableChildData(
                  startingRatio: 0.5,
                  child: SizedBox.expand(
                    key: Key('BoxB'),
                  ),
                ),
              ],
              direction: Axis.horizontal,
              controller: controller,
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
      final controller = ResizableController();
      await tester.binding.setSurfaceSize(const Size(1000, 1000));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              dividerWidth: dividerWidth,
              children: const [
                ResizableChildData(
                  startingRatio: 0.5,
                  child: SizedBox.expand(
                    key: Key('BoxA'),
                  ),
                ),
                ResizableChildData(
                  startingRatio: 0.5,
                  child: SizedBox.expand(
                    key: Key('BoxB'),
                  ),
                ),
              ],
              direction: Axis.horizontal,
              controller: controller,
            ),
          ),
        ),
      );

      const availableSpace = 1000 - dividerWidth;
      expect(controller.availableSpace, availableSpace);

      final resizableContainer = tester.widget(find.byType(ResizableContainer));
      expect(resizableContainer, isNotNull);

      controller.setRatios([0.6, 0.4]);
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
              direction: Axis.horizontal,
              children: const [
                ResizableChildData(
                  child: SizedBox.expand(
                    key: Key('BoxA'),
                  ),
                  startingRatio: 0.5,
                  minSize: 200,
                ),
                ResizableChildData(
                  child: SizedBox.expand(),
                  startingRatio: 0.5,
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
    });

    testWidgets('container respects max size', (tester) async {
      const dividerWidth = 2.0;
      await tester.binding.setSurfaceSize(const Size(1000, 1000));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              dividerWidth: dividerWidth,
              direction: Axis.horizontal,
              children: const [
                ResizableChildData(
                  child: SizedBox.expand(
                    key: Key('BoxA'),
                  ),
                  startingRatio: 0.5,
                  maxSize: 700,
                ),
                ResizableChildData(
                  child: SizedBox.expand(
                    key: Key('BoxB'),
                  ),
                  startingRatio: 0.5,
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
              dividerWidth: dividerWidth,
              direction: Axis.horizontal,
              children: const [
                ResizableChildData(
                  child: SizedBox.expand(
                    key: Key('BoxA'),
                  ),
                  startingRatio: 0.5,
                  minSize: 200,
                ),
                ResizableChildData(
                  child: SizedBox.expand(
                    key: Key('BoxB'),
                  ),
                  startingRatio: 0.5,
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
  });
}

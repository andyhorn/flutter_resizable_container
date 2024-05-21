import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(ResizableContainer, () {
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
              divider: const ResizableDivider(
                size: dividerWidth,
              ),
              children: const [
                ResizableChild(
                  startingSize: ResizableSize.ratio(0.5),
                  child: SizedBox.expand(
                    key: Key('BoxA'),
                  ),
                ),
                ResizableChild(
                  startingSize: ResizableSize.ratio(0.5),
                  child: SizedBox.expand(
                    key: Key('BoxB'),
                  ),
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
      final controller = ResizableController();

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
                ResizableChild(
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

      // The sizes are not exactly their ratio because the divider width is 2.0
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
                  minSize: 200,
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
              divider: ResizableDivider(
                size: dividerWidth,
              ),
              direction: Axis.horizontal,
              children: [
                ResizableChild(
                  maxSize: 700,
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
              divider: ResizableDivider(
                size: dividerWidth,
              ),
              direction: Axis.horizontal,
              children: [
                ResizableChild(
                  minSize: 200,
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

        await widgetTester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResizableContainer(
                direction: Axis.horizontal,
                divider: ResizableDivider(
                  size: 2.0,
                ),
                children: [
                  ResizableChild(
                    startingSize: ResizableSize.ratio(0.5),
                    child: SizedBox.expand(
                      key: Key('Box A'),
                    ),
                  ),
                  ResizableChild(
                    child: SizedBox.expand(
                      key: Key('Box B'),
                    ),
                  ),
                  ResizableChild(
                    child: SizedBox.expand(
                      key: Key('Box C'),
                    ),
                  ),
                ],
              ),
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

    testWidgets('children do not expand if set to false', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1000));
      await tester.pumpWidget(const _ToggleChildApp(expand: false));

      expect(find.byKey(const Key('ChildA')), findsOneWidget);
      expect(find.byKey(const Key('ChildB')), findsOneWidget);

      expect(
        tester.getSize(find.byKey(const Key('ChildA'))).width,
        equals(499.0),
      );
      expect(
        tester.getSize(find.byKey(const Key('ChildB'))).width,
        equals(499.0),
      );

      await tester.tap(find.byKey(const Key('ToggleSwitch')));
      await tester.pump();

      expect(find.byKey(const Key('ChildA')), findsOneWidget);
      expect(find.byKey(const Key('ChildB')), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key('ChildA'))).width,
        equals(500),
      );
    });

    testWidgets('children auto-expand if set to true', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1000));
      await tester.pumpWidget(const _ToggleChildApp(expand: true));

      expect(find.byKey(const Key('ChildA')), findsOneWidget);
      expect(find.byKey(const Key('ChildB')), findsOneWidget);

      expect(
        tester.getSize(find.byKey(const Key('ChildA'))).width,
        equals(499.0),
      );
      expect(
        tester.getSize(find.byKey(const Key('ChildB'))).width,
        equals(499.0),
      );

      await tester.tap(find.byKey(const Key('ToggleSwitch')));
      await tester.pump();

      expect(find.byKey(const Key('ChildA')), findsOneWidget);
      expect(find.byKey(const Key('ChildB')), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key('ChildA'))).width,
        equals(1000),
      );
    });
  });
}

class _ToggleChildApp extends StatefulWidget {
  const _ToggleChildApp({required this.expand});

  final bool expand;

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
            ResizableChild(
              startingSize: const ResizableSize.ratio(0.5),
              expand: widget.expand,
              child: const SizedBox.expand(
                key: Key('ChildA'),
              ),
            ),
            if (!hidden)
              const ResizableChild(
                startingSize: ResizableSize.ratio(0.5),
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

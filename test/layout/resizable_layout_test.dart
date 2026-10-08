import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/layout/resizable_layout.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountingPainter extends CustomPainter {
  _CountingPainter(this.counter);

  final ValueNotifier<int> counter;

  @override
  void paint(Canvas canvas, Size size) => counter.value++;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

void main() {
  group(ResizableLayout, () {
    const childA = Key('a');
    const dividerKey = Key('divider');
    const childB = Key('b');
    const layoutKey = Key('layout');

    Widget buildLayout({
      List<double>? fixedSizes,
      List<ResizableSize> sizes = const [
        ResizableSize.pixels(100),
        ResizableSize.expand(),
      ],
      ValueChanged<List<double>>? onComplete,
      TextDirection textDirection = TextDirection.ltr,
      Widget divider = const SizedBox(key: dividerKey),
    }) {
      return Directionality(
        textDirection: textDirection,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 600,
            height: 100,
            child: ResizableLayout(
              key: layoutKey,
              direction: Axis.horizontal,
              sizes: sizes,
              resizableChildren: [
                for (final size in sizes)
                  ResizableChild(
                    size: size,
                    divider: const ResizableDivider(thickness: 2),
                    child: const SizedBox(),
                  ),
              ],
              fixedSizes: fixedSizes,
              onComplete: onComplete ?? (_) {},
              children: [
                const SizedBox(key: childA),
                divider,
                const SizedBox(key: childB),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('fixed mode lays out at the given sizes and never completes',
        (tester) async {
      var completions = 0;

      await tester.pumpWidget(
        buildLayout(
          fixedSizes: const [100, 2, 498],
          onComplete: (_) => completions++,
        ),
      );

      expect(tester.getSize(find.byKey(childA)).width, 100);
      expect(tester.getSize(find.byKey(dividerKey)).width, 2);
      expect(tester.getSize(find.byKey(childB)).width, 498);
      expect(completions, 0);
    });

    testWidgets('measure mode completes once per layout', (tester) async {
      final reported = <List<double>>[];

      await tester.pumpWidget(buildLayout(onComplete: reported.add));

      expect(reported, [
        [100, 2, 498],
      ]);

      await tester.pumpWidget(buildLayout(onComplete: reported.add));
      expect(reported, hasLength(1));

      await tester.pumpWidget(
        buildLayout(
          onComplete: reported.add,
          sizes: const [
            ResizableSize.pixels(200),
            ResizableSize.expand(),
          ],
        ),
      );
      expect(reported, hasLength(2));
      expect(reported.last, [200, 2, 398]);
    });

    testWidgets('measures when fixed sizes do not match the child count',
        (tester) async {
      final reported = <List<double>>[];

      await tester.pumpWidget(
        buildLayout(
          fixedSizes: const [100, 2],
          onComplete: reported.add,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(reported, [
        [100, 2, 498],
      ]);
    });

    testWidgets('omits zero-extent children from semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        buildLayout(
          fixedSizes: const [100, 0, 500],
          divider: Semantics(
            label: 'collapsed divider',
            child: SizedBox(key: dividerKey),
          ),
        ),
      );

      expect(find.bySemanticsLabel('collapsed divider'), findsNothing);

      await tester.pumpWidget(
        buildLayout(
          fixedSizes: const [100, 2, 498],
          divider: Semantics(
            label: 'collapsed divider',
            child: SizedBox(key: dividerKey),
          ),
        ),
      );

      expect(find.bySemanticsLabel('collapsed divider'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('mirrors child offsets in right-to-left', (tester) async {
      await tester.pumpWidget(
        buildLayout(
          fixedSizes: const [100, 2, 498],
          textDirection: TextDirection.rtl,
        ),
      );

      expect(tester.getTopLeft(find.byKey(childA)).dx, 500);
      expect(tester.getTopLeft(find.byKey(dividerKey)).dx, 498);
      expect(tester.getTopLeft(find.byKey(childB)).dx, 0);
    });

    testWidgets('re-lays out when the text direction changes', (tester) async {
      await tester.pumpWidget(buildLayout(fixedSizes: const [100, 2, 498]));
      expect(tester.getTopLeft(find.byKey(childA)).dx, 0);

      await tester.pumpWidget(
        buildLayout(
          fixedSizes: const [100, 2, 498],
          textDirection: TextDirection.rtl,
        ),
      );

      expect(tester.getTopLeft(find.byKey(childA)).dx, 500);
      expect(tester.getTopLeft(find.byKey(dividerKey)).dx, 498);
      expect(tester.getTopLeft(find.byKey(childB)).dx, 0);
    });

    testWidgets('lays out left-to-right by default', (tester) async {
      await tester.pumpWidget(buildLayout(fixedSizes: const [100, 2, 498]));

      expect(tester.getTopLeft(find.byKey(childA)).dx, 0);
      expect(tester.getTopLeft(find.byKey(dividerKey)).dx, 100);
      expect(tester.getTopLeft(find.byKey(childB)).dx, 102);
    });

    testWidgets('does not paint a zero-extent child', (tester) async {
      final paints = ValueNotifier(0);

      await tester.pumpWidget(
        buildLayout(
          fixedSizes: const [100, 0, 500],
          divider: SizedBox(
            key: dividerKey,
            child: CustomPaint(painter: _CountingPainter(paints)),
          ),
        ),
      );
      expect(paints.value, 0);

      await tester.pumpWidget(
        buildLayout(
          fixedSizes: const [100, 2, 498],
          divider: SizedBox(
            key: dividerKey,
            child: CustomPaint(painter: _CountingPainter(paints)),
          ),
        ),
      );
      expect(paints.value, 1);
    });

    testWidgets('dry layout reports the biggest size the constraints allow',
        (tester) async {
      await tester.pumpWidget(buildLayout());

      final renderBox = tester.renderObject<RenderBox>(find.byKey(layoutKey));
      const constraints = BoxConstraints(
        minWidth: 10,
        maxWidth: 300,
        minHeight: 20,
        maxHeight: 80,
      );

      expect(renderBox.getDryLayout(constraints), constraints.biggest);
    });
  });
}

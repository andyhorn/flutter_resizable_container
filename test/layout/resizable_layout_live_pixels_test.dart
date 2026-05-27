import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/layout/resizable_layout.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResizableLayout live-pixel path', () {
    testWidgets(
      'lays out children using the supplied pixel values',
      (tester) async {
        final pixels = ValueNotifier<List<double>>(const [120, 280]);
        addTearDown(pixels.dispose);

        await _pumpLayout(tester, pixels: pixels);

        expect(_widthOf(tester, const Key('A')), 120);
        expect(_widthOf(tester, const Key('B')), 280);
      },
    );

    testWidgets(
      'relayouts in response to pixel changes without rebuilding children',
      (tester) async {
        final pixels = ValueNotifier<List<double>>(const [120, 280]);
        addTearDown(pixels.dispose);
        var aBuildCount = 0;
        var bBuildCount = 0;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 402,
              height: 100,
              child: ResizableLayout(
                direction: Axis.horizontal,
                onComplete: (_) {},
                sizes: const [
                  ResizableSize.pixels(120),
                  ResizableSize.pixels(280),
                ],
                resizableChildren: const [
                  ResizableChild(
                    size: ResizableSize.pixels(120),
                    divider: ResizableDivider(thickness: 2),
                    child: SizedBox(key: Key('A')),
                  ),
                  ResizableChild(
                    size: ResizableSize.pixels(280),
                    child: SizedBox(key: Key('B')),
                  ),
                ],
                livePixels: pixels,
                children: [
                  Builder(
                    key: const Key('A'),
                    builder: (context) {
                      aBuildCount++;
                      return const SizedBox();
                    },
                  ),
                  const ResizableContainerDivider.placeholder(
                    config: ResizableDivider(thickness: 2),
                    direction: Axis.horizontal,
                  ),
                  Builder(
                    key: const Key('B'),
                    builder: (context) {
                      bBuildCount++;
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        final aInitial = aBuildCount;
        final bInitial = bBuildCount;
        expect(_widthOf(tester, const Key('A')), 120);
        expect(_widthOf(tester, const Key('B')), 280);

        pixels.value = const [200, 200];
        await tester.pump();

        // The render object relayouts but the child Builders are not asked
        // to rebuild.
        expect(aBuildCount, aInitial);
        expect(bBuildCount, bInitial);
        expect(_widthOf(tester, const Key('A')), 200);
        expect(_widthOf(tester, const Key('B')), 200);
      },
    );

    testWidgets(
      'switching livePixels from null to a notifier picks up the new source',
      (tester) async {
        final pixels = ValueNotifier<List<double>>(const [200, 200]);
        addTearDown(pixels.dispose);

        // First pump: livePixels=null forces the cold path, which resolves
        // the declared sizes (120 + 280).
        await _pumpLayout(tester, pixels: null);
        expect(_widthOf(tester, const Key('A')), 120);
        expect(_widthOf(tester, const Key('B')), 280);

        // Second pump: livePixels supplied — the render object switches to
        // the live path and the notifier's values become authoritative.
        await _pumpLayout(tester, pixels: pixels);
        expect(_widthOf(tester, const Key('A')), 200);
        expect(_widthOf(tester, const Key('B')), 200);
      },
    );

    testWidgets(
      'switching livePixels from a notifier to null falls back to cold path',
      (tester) async {
        final pixels = ValueNotifier<List<double>>(const [200, 200]);
        addTearDown(pixels.dispose);

        await _pumpLayout(tester, pixels: pixels);
        expect(_widthOf(tester, const Key('A')), 200);

        // Drop the listenable — should fall back to resolving from sizes.
        await _pumpLayout(tester, pixels: null);
        expect(_widthOf(tester, const Key('A')), 120);
        expect(_widthOf(tester, const Key('B')), 280);

        // And the old notifier must no longer drive the render object —
        // mutating it after the swap should not affect layout.
        pixels.value = const [50, 50];
        await tester.pump();
        expect(_widthOf(tester, const Key('A')), 120);
      },
    );

    testWidgets(
      'swapping in a fresh notifier rebinds the subscription',
      (tester) async {
        final first = ValueNotifier<List<double>>(const [100, 300]);
        final second = ValueNotifier<List<double>>(const [300, 100]);
        addTearDown(first.dispose);
        addTearDown(second.dispose);

        await _pumpLayout(tester, pixels: first);
        expect(_widthOf(tester, const Key('A')), 100);

        await _pumpLayout(tester, pixels: second);
        expect(_widthOf(tester, const Key('A')), 300);

        // The old notifier must be detached after the swap.
        first.value = const [50, 350];
        await tester.pump();
        expect(_widthOf(tester, const Key('A')), 300);

        // The new notifier drives layout.
        second.value = const [200, 200];
        await tester.pump();
        expect(_widthOf(tester, const Key('A')), 200);
      },
    );

    testWidgets(
      'reverses offsets when text direction is RTL',
      (tester) async {
        const surfaceWidth = 402.0;
        await tester.binding.setSurfaceSize(const Size(surfaceWidth, 100));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final pixels = ValueNotifier<List<double>>(const [100, 300]);
        addTearDown(pixels.dispose);

        await _pumpLayout(
          tester,
          pixels: pixels,
          textDirection: TextDirection.rtl,
        );

        // 100 + 2 (divider) + 300 = 402. In RTL, A (size 100) starts at
        // surfaceWidth - 100; B (size 300) starts at 0.
        final boxA = tester.getTopLeft(find.byKey(const Key('A')));
        final boxB = tester.getTopLeft(find.byKey(const Key('B')));
        expect(boxA.dx, surfaceWidth - 100);
        expect(boxB.dx, 0);
      },
    );

    testWidgets(
      'collapses divider to zero when adjacent child is hidden',
      (tester) async {
        final pixels = ValueNotifier<List<double>>(const [100, 0, 300]);
        addTearDown(pixels.dispose);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 404,
              height: 100,
              child: ResizableLayout(
                direction: Axis.horizontal,
                onComplete: (_) {},
                sizes: const [
                  ResizableSize.pixels(100),
                  ResizableSize.pixels(0),
                  ResizableSize.pixels(300),
                ],
                resizableChildren: const [
                  ResizableChild(
                    size: ResizableSize.pixels(100),
                    divider: ResizableDivider(thickness: 2),
                    child: SizedBox(key: Key('A')),
                  ),
                  ResizableChild(
                    size: ResizableSize.pixels(0),
                    divider: ResizableDivider(thickness: 2),
                    child: SizedBox(key: Key('B')),
                  ),
                  ResizableChild(
                    size: ResizableSize.pixels(300),
                    child: SizedBox(key: Key('C')),
                  ),
                ],
                hiddenIndices: const {1},
                livePixels: pixels,
                children: const [
                  SizedBox(key: Key('A')),
                  ResizableContainerDivider.placeholder(
                    config: ResizableDivider(thickness: 2),
                    direction: Axis.horizontal,
                  ),
                  SizedBox(key: Key('B')),
                  ResizableContainerDivider.placeholder(
                    config: ResizableDivider(thickness: 2),
                    direction: Axis.horizontal,
                  ),
                  SizedBox(key: Key('C')),
                ],
              ),
            ),
          ),
        );

        // C should be flush against A's right edge — both adjacent dividers
        // collapse to zero because index 1 is hidden.
        final boxA = tester.getTopLeft(find.byKey(const Key('A')));
        final boxC = tester.getTopLeft(find.byKey(const Key('C')));
        expect(boxA.dx, 0);
        expect(boxC.dx, 100);
      },
    );
  });
}

double _widthOf(WidgetTester tester, Key key) {
  return tester.getSize(find.byKey(key)).width;
}

Future<void> _pumpLayout(
  WidgetTester tester, {
  required ValueListenable<List<double>>? pixels,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return tester.pumpWidget(
    Directionality(
      textDirection: textDirection,
      child: SizedBox(
        width: 402,
        height: 100,
        child: ResizableLayout(
          direction: Axis.horizontal,
          onComplete: (_) {},
          sizes: const [
            ResizableSize.pixels(120),
            ResizableSize.pixels(280),
          ],
          resizableChildren: const [
            ResizableChild(
              size: ResizableSize.pixels(120),
              divider: ResizableDivider(thickness: 2),
              child: SizedBox(key: Key('A')),
            ),
            ResizableChild(
              size: ResizableSize.pixels(280),
              child: SizedBox(key: Key('B')),
            ),
          ],
          livePixels: pixels,
          children: const [
            SizedBox(key: Key('A')),
            ResizableContainerDivider.placeholder(
              config: ResizableDivider(thickness: 2),
              direction: Axis.horizontal,
            ),
            SizedBox(key: Key('B')),
          ],
        ),
      ),
    ),
  );
}

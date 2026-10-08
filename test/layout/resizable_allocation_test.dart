import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/layout/resizable_allocation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('allocateSizes', () {
    const divider = ResizableDivider(thickness: 2);

    List<double> allocate({
      required double extent,
      required List<ResizableSize> sizes,
      Set<int> hidden = const {},
      double Function(int index, double cap)? measureShrink,
    }) {
      return allocateSizes(
        extent: extent,
        sizes: sizes,
        dividers: List.filled(sizes.length - 1, divider),
        hiddenIndices: hidden,
        measureShrink: measureShrink ?? (_, __) => fail('unexpected measure'),
      );
    }

    test('lays out pixels with dividers between children', () {
      final result = allocate(
        extent: 600,
        sizes: const [
          ResizableSize.pixels(100),
          ResizableSize.pixels(200),
          ResizableSize.pixels(50),
        ],
      );

      expect(result, [100, 2, 200, 2, 50]);
    });

    test('divides the space left after dividers by ratio', () {
      final result = allocate(
        extent: 502,
        sizes: const [ResizableSize.ratio(0.5), ResizableSize.ratio(0.5)],
      );

      expect(result, [250, 2, 250]);
    });

    test('weights expand children by flex', () {
      final result = allocate(
        extent: 602,
        sizes: const [
          ResizableSize.expand(),
          ResizableSize.expand(flex: 2),
        ],
      );

      expect(result, [200, 2, 400]);
    });

    test('redistributes space freed by a clamped expand child', () {
      final result = allocate(
        extent: 602,
        sizes: const [
          ResizableSize.expand(max: 100),
          ResizableSize.expand(),
        ],
      );

      expect(result, [100, 2, 500]);
    });

    test('honors min on expand children', () {
      final result = allocate(
        extent: 302,
        sizes: const [
          ResizableSize.expand(min: 250),
          ResizableSize.expand(),
        ],
      );

      expect(result, [250, 2, 50]);
    });

    test('recomputes flex shares after a max violation', () {
      final result = allocate(
        extent: 404,
        sizes: const [
          ResizableSize.expand(max: 50),
          ResizableSize.expand(),
          ResizableSize.expand(flex: 2),
        ],
      );

      expect(result[0], 50);
      expect(result[2], moreOrLessEquals(350 / 3));
      expect(result[4], moreOrLessEquals(700 / 3));
    });

    test('recomputes flex shares after a min violation', () {
      final result = allocate(
        extent: 404,
        sizes: const [
          ResizableSize.expand(min: 200),
          ResizableSize.expand(),
          ResizableSize.expand(flex: 2),
        ],
      );

      expect(result[0], 200);
      expect(result[2], moreOrLessEquals(200 / 3));
      expect(result[4], moreOrLessEquals(400 / 3));
    });

    test('freezes only the net violation direction', () {
      final result = allocate(
        extent: 492,
        sizes: const [
          ResizableSize.expand(flex: 3, max: 145),
          ResizableSize.expand(flex: 3, min: 283),
          ResizableSize.expand(flex: 2, max: 196),
        ],
      );

      expect(result, [123, 2, 283, 2, 82]);
    });

    test('ends at the minimums when space is too small', () {
      final result = allocate(
        extent: 102,
        sizes: const [
          ResizableSize.expand(min: 80),
          ResizableSize.expand(min: 60),
        ],
      );

      expect(result, [80, 2, 60]);
    });

    test('terminates in an unbounded extent', () {
      final result = allocate(
        extent: double.infinity,
        sizes: const [ResizableSize.expand(), ResizableSize.expand()],
      );

      expect(result, [double.infinity, 2, double.infinity]);
    });

    test('clamps the measured shrink size and passes the remaining cap', () {
      final caps = <int, double>{};
      final result = allocate(
        extent: 602,
        sizes: const [
          ResizableSize.pixels(100),
          ResizableSize.shrink(max: 80),
          ResizableSize.expand(),
        ],
        measureShrink: (index, cap) {
          caps[index] = cap;
          return 120;
        },
      );

      expect(caps, {1: 498});
      expect(result, [100, 2, 80, 2, 418]);
    });

    test('raises a measured shrink size to its min', () {
      final result = allocate(
        extent: 302,
        sizes: const [
          ResizableSize.shrink(min: 50),
          ResizableSize.expand(),
        ],
        measureShrink: (_, __) => 20,
      );

      expect(result, [50, 2, 250]);
    });

    test('collapses the dividers next to a hidden child', () {
      final result = allocate(
        extent: 602,
        sizes: const [
          ResizableSize.pixels(100),
          ResizableSize.pixels(0),
          ResizableSize.expand(),
        ],
        hidden: const {1},
      );

      expect(result, [100, 0, 0, 0, 502]);
    });

    test('allocates mixed sizes in order', () {
      final result = allocate(
        extent: 606,
        sizes: const [
          ResizableSize.pixels(100),
          ResizableSize.ratio(0.5),
          ResizableSize.shrink(),
          ResizableSize.expand(),
        ],
        measureShrink: (_, __) => 50,
      );

      expect(result, [100, 2, 225, 2, 50, 2, 225]);
    });
  });

  group('dividerExtent', () {
    const divider = ResizableDivider(thickness: 2, padding: 3);

    test('is thickness plus padding when neither neighbour is hidden', () {
      expect(dividerExtent(divider, const {}, 0), 5);
    });

    test('is zero when the preceding child is hidden', () {
      expect(dividerExtent(divider, const {1}, 1), 0);
    });

    test('is zero when the following child is hidden', () {
      expect(dividerExtent(divider, const {2}, 1), 0);
    });
  });
}

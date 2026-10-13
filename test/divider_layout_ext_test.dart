import 'package:flutter/widgets.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/extensions/divider_layout_ext.dart';
import 'package:flutter_test/flutter_test.dart';

const _constraints = BoxConstraints(maxWidth: 400, maxHeight: 300);
const _thickness = 4.0;
const _padding = 6.0;
const _hitSlop = 12.0;

ResizableDivider _divider({
  ResizableSize length = const ResizableSize.expand(),
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  double hitSlop = _hitSlop,
}) {
  return ResizableDivider(
    thickness: _thickness,
    padding: _padding,
    hitSlop: hitSlop,
    length: length,
    crossAxisAlignment: crossAxisAlignment,
  );
}

void main() {
  group('DividerLayoutExt', () {
    group('alignmentFor', () {
      const expected = {
        (CrossAxisAlignment.start, Axis.horizontal): Alignment.topCenter,
        (CrossAxisAlignment.start, Axis.vertical): Alignment.centerLeft,
        (CrossAxisAlignment.end, Axis.horizontal): Alignment.bottomCenter,
        (CrossAxisAlignment.end, Axis.vertical): Alignment.bottomRight,
        (CrossAxisAlignment.center, Axis.horizontal): Alignment.center,
        (CrossAxisAlignment.center, Axis.vertical): Alignment.center,
        (CrossAxisAlignment.stretch, Axis.horizontal): Alignment.center,
        (CrossAxisAlignment.stretch, Axis.vertical): Alignment.center,
        (CrossAxisAlignment.baseline, Axis.horizontal): Alignment.center,
        (CrossAxisAlignment.baseline, Axis.vertical): Alignment.center,
      };

      for (final alignment in CrossAxisAlignment.values) {
        for (final direction in Axis.values) {
          test(
              'is ${expected[(alignment, direction)]} for $alignment '
              'in a $direction container', () {
            final divider = _divider(crossAxisAlignment: alignment);

            expect(
              divider.alignmentFor(direction),
              expected[(alignment, direction)],
            );
          });
        }
      }

      test('covers every alignment and direction', () {
        expect(
          expected.keys.length,
          CrossAxisAlignment.values.length * Axis.values.length,
        );
      });
    });

    group('sizeFor', () {
      const mainAxisExtent = _thickness + _padding;

      for (final alignment in CrossAxisAlignment.values) {
        group('with $alignment', () {
          test('stretches an expand length across a horizontal container', () {
            final divider = _divider(crossAxisAlignment: alignment);

            expect(
              divider.sizeFor(Axis.horizontal, _constraints),
              const Size(mainAxisExtent, 300),
            );
          });

          test('stretches an expand length across a vertical container', () {
            final divider = _divider(crossAxisAlignment: alignment);

            expect(
              divider.sizeFor(Axis.vertical, _constraints),
              const Size(400, mainAxisExtent),
            );
          });
        });
      }

      for (final direction in Axis.values) {
        final isHorizontal = direction == Axis.horizontal;
        final crossExtent = isHorizontal ? 300.0 : 400.0;

        Size sizeWithCross(double cross) {
          return isHorizontal
              ? Size(mainAxisExtent, cross)
              : Size(cross, mainAxisExtent);
        }

        group('in a $direction container', () {
          test('uses a pixel length smaller than the space', () {
            final divider = _divider(length: const ResizableSize.pixels(100));

            expect(
              divider.sizeFor(direction, _constraints),
              sizeWithCross(100),
            );
          });

          test('caps a pixel length at the space', () {
            final divider = _divider(length: const ResizableSize.pixels(1000));

            expect(
              divider.sizeFor(direction, _constraints),
              sizeWithCross(crossExtent),
            );
          });

          test('takes a ratio of the space', () {
            final divider = _divider(length: const ResizableSize.ratio(0.5));

            expect(
              divider.sizeFor(direction, _constraints),
              sizeWithCross(crossExtent * 0.5),
            );
          });
        });
      }
    });

    group('hitAreaFor', () {
      const mainAxisExtent = _thickness + _padding;

      for (final alignment in CrossAxisAlignment.values) {
        group('with $alignment', () {
          test('widens only the width of a horizontal container', () {
            final divider = _divider(crossAxisAlignment: alignment);

            expect(
              divider.hitAreaFor(Axis.horizontal, _constraints),
              const Size(mainAxisExtent + 2 * _hitSlop, 300),
            );
          });

          test('widens only the height of a vertical container', () {
            final divider = _divider(crossAxisAlignment: alignment);

            expect(
              divider.hitAreaFor(Axis.vertical, _constraints),
              const Size(400, mainAxisExtent + 2 * _hitSlop),
            );
          });
        });
      }

      for (final direction in Axis.values) {
        test('equals sizeFor without a hitSlop in a $direction container', () {
          final divider = _divider(
            hitSlop: 0,
            length: const ResizableSize.pixels(100),
          );

          expect(
            divider.hitAreaFor(direction, _constraints),
            divider.sizeFor(direction, _constraints),
          );
        });

        test('keeps the cross-axis length in a $direction container', () {
          final divider = _divider(length: const ResizableSize.ratio(0.5));

          final size = divider.sizeFor(direction, _constraints);
          final hitArea = divider.hitAreaFor(direction, _constraints);

          final isHorizontal = direction == Axis.horizontal;
          final sizeCross = isHorizontal ? size.height : size.width;
          final hitAreaCross = isHorizontal ? hitArea.height : hitArea.width;
          expect(hitAreaCross, sizeCross);
        });
      }
    });
  });
}

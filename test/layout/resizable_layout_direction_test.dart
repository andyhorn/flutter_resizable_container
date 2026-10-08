import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/src/layout/resizable_layout_direction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(ResizableLayoutDirection, () {
    group('forAxis', () {
      test('returns vertical layout for vertical Axis', () {
        final direction = ResizableLayoutDirection.forAxis(Axis.vertical);

        expect(direction, isA<ResizableVerticalLayout>());
      });

      test('returns horizontal layout for horizontal Axis', () {
        final direction = ResizableLayoutDirection.forAxis(Axis.horizontal);

        expect(direction, isA<ResizableHorizontalLayout>());
      });
    });

    group(ResizableHorizontalLayout, () {
      final layout = ResizableHorizontalLayout();

      test('getMaxConstraint returns maxWidth from constraints', () {
        final constraints = BoxConstraints(maxWidth: 100, maxHeight: 200);

        final result = layout.getMaxConstraint(constraints);

        expect(result, 100);
      });

      test('getOffset returns Offset with x position', () {
        final result = layout.getOffset(100);

        expect(result, const Offset(100, 0));
      });

      test('getRtlOffset mirrors the x position within the container', () {
        final result = layout.getRtlOffset(100, 50, const Size(400, 200));

        expect(result, const Offset(250, 0));
      });

      test('getSizeDimension returns width from size', () {
        final size = const Size(100, 200);

        final result = layout.getSizeDimension(size);

        expect(result, 100);
      });

      test('getSize returns Size with value and maxHeight', () {
        final constraints = BoxConstraints(maxWidth: 100, maxHeight: 200);

        final result = layout.getSize(100, constraints);

        expect(result, const Size(100, 200));
      });
    });

    group(ResizableVerticalLayout, () {
      final layout = ResizableVerticalLayout();

      test('getMaxConstraint returns maxHeight from constraints', () {
        final constraints = BoxConstraints(maxWidth: 100, maxHeight: 200);

        final result = layout.getMaxConstraint(constraints);

        expect(result, 200);
      });

      test('getOffset returns Offset with y position', () {
        final result = layout.getOffset(100);

        expect(result, const Offset(0, 100));
      });

      test('getRtlOffset leaves the y position unchanged', () {
        final result = layout.getRtlOffset(100, 50, const Size(400, 200));

        expect(result, const Offset(0, 100));
      });

      test('getSizeDimension returns height from size', () {
        final size = const Size(100, 200);

        final result = layout.getSizeDimension(size);

        expect(result, 200);
      });

      test('getSize returns Size with value and maxWidth', () {
        final constraints = BoxConstraints(maxWidth: 100, maxHeight: 200);

        final result = layout.getSize(200, constraints);

        expect(result, const Size(100, 200));
      });
    });
  });
}

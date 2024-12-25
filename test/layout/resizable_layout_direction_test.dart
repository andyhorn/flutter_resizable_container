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

      testWidgets('getMinIntrinsicDimension return min intrinsic width',
          (tester) async {
        final key = GlobalKey();
        final child = SizedBox(key: key, height: 100, width: 200);

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Center(
              child: child,
            ),
          ),
        ));

        final renderBox = key.currentContext?.findRenderObject() as RenderBox?;

        if (renderBox == null) {
          throw Exception('RenderBox not found');
        }

        final result = layout.getMinIntrinsicDimension(renderBox);

        expect(result, 200);
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

      testWidgets('getMinIntrinsicDimension return min intrinsic height',
          (tester) async {
        final key = GlobalKey();
        final child = SizedBox(key: key, height: 100, width: 200);

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Center(
              child: child,
            ),
          ),
        ));

        final renderBox = key.currentContext?.findRenderObject() as RenderBox?;

        if (renderBox == null) {
          throw Exception('RenderBox not found');
        }

        final result = layout.getMinIntrinsicDimension(renderBox);

        expect(result, 100);
      });
    });
  });
}

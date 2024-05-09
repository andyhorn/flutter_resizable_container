import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/src/resizable_child.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(ResizableChild, () {
    group('startingRatio', () {
      test('throws if less than 0', () {
        expect(
          () => ResizableChild(startingRatio: -0.1, child: const SizedBox()),
          throwsAssertionError,
        );
      });

      test('throws if greater than 1', () {
        expect(
          () => ResizableChild(startingRatio: 1.1, child: const SizedBox()),
          throwsAssertionError,
        );
      });

      test('allows null', () {
        expect(
          () => const ResizableChild(startingRatio: null, child: SizedBox()),
          isNot(throwsA(anything)),
        );
      });

      test('allows a value between 0 and 1', () {
        expect(
          () => const ResizableChild(startingRatio: 0.5, child: SizedBox()),
          isNot(throwsA(anything)),
        );
      });

      test('allows 0', () {
        expect(
          () => const ResizableChild(startingRatio: 0, child: SizedBox()),
          isNot(throwsA(anything)),
        );
      });

      test('allows 1', () {
        expect(
          () => const ResizableChild(startingRatio: 1, child: SizedBox()),
          isNot(throwsA(anything)),
        );
      });
    });
  });
}

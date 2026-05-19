import 'package:flutter/animation.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(ResizableHideAnimation, () {
    test('defaults to a 200ms easeInOut animation', () {
      const animation = ResizableHideAnimation();

      expect(animation.duration, const Duration(milliseconds: 200));
      expect(animation.curve, Curves.easeInOut);
    });

    test('two instances with the same fields are equal', () {
      const a = ResizableHideAnimation(
        duration: Duration(milliseconds: 300),
        curve: Curves.linear,
      );
      const b = ResizableHideAnimation(
        duration: Duration(milliseconds: 300),
        curve: Curves.linear,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differs when duration differs', () {
      const a = ResizableHideAnimation(
        duration: Duration(milliseconds: 100),
      );
      const b = ResizableHideAnimation(
        duration: Duration(milliseconds: 200),
      );

      expect(a, isNot(equals(b)));
    });

    test('differs when curve differs', () {
      const a = ResizableHideAnimation(curve: Curves.linear);
      const b = ResizableHideAnimation(curve: Curves.easeIn);

      expect(a, isNot(equals(b)));
    });
  });
}

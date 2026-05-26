import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(ResizableChild, () {
    group('equality', () {
      test('equal when size, divider, and child are equal', () {
        const child = SizedBox();
        const a = ResizableChild(child: child);
        const b = ResizableChild(child: child);
        expect(a, equals(b));
      });

      test('not equal when divider differs', () {
        const a = ResizableChild(
          child: SizedBox(),
          divider: ResizableDivider(thickness: 1),
        );
        const b = ResizableChild(
          child: SizedBox(),
          divider: ResizableDivider(thickness: 2),
        );
        expect(a, isNot(equals(b)));
      });

      test('not equal when divider color differs', () {
        const a = ResizableChild(
          child: SizedBox(),
          divider: ResizableDivider(color: Color(0xFF000000)),
        );
        const b = ResizableChild(
          child: SizedBox(),
          divider: ResizableDivider(color: Color(0xFFFFFFFF)),
        );
        expect(a, isNot(equals(b)));
      });

      test('not equal when distinct keyless children of same type differ', () {
        final a = ResizableChild(child: Text('one'));
        final b = ResizableChild(child: Text('two'));
        expect(a, isNot(equals(b)));
      });

      test('not equal when size differs', () {
        const a = ResizableChild(
          child: SizedBox(),
          size: ResizableSize.pixels(100),
        );
        const b = ResizableChild(
          child: SizedBox(),
          size: ResizableSize.pixels(200),
        );
        expect(a, isNot(equals(b)));
      });
    });
  });
}

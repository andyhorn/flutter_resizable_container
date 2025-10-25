import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResizableChild', () {
    group('equality', () {
      test('instances with same properties are equal', () {
        const child1 = ResizableChild(
          id: 'test_id',
          child: SizedBox.shrink(),
          visible: true,
        );

        const child2 = ResizableChild(
          id: 'test_id',
          child: SizedBox.shrink(),
          visible: true,
        );

        expect(child1, equals(child2));
        expect(child1.hashCode, equals(child2.hashCode));
      });

      test('instances with different visible flags are not equal', () {
        const child1 = ResizableChild(
          id: 'test_id',
          child: SizedBox.shrink(),
          visible: true,
        );

        const child2 = ResizableChild(
          id: 'test_id',
          child: SizedBox.shrink(),
          visible: false,
        );

        expect(child1, isNot(equals(child2)));
        expect(child1.hashCode, isNot(equals(child2.hashCode)));
      });

      test('instances with different sizes are not equal', () {
        const child1 = ResizableChild(
          id: 'test_id',
          child: SizedBox.shrink(),
          size: ResizableSize.pixels(100),
          visible: true,
        );

        const child2 = ResizableChild(
          id: 'test_id',
          child: SizedBox.shrink(),
          size: ResizableSize.pixels(200),
          visible: true,
        );

        expect(child1, isNot(equals(child2)));
        expect(child1.hashCode, isNot(equals(child2.hashCode)));
      });

      test('instances with different child keys are not equal', () {
        const child1 = ResizableChild(
          id: 'test_id',
          child: SizedBox(key: Key('key1')),
          visible: true,
        );

        const child2 = ResizableChild(
          id: 'test_id',
          child: SizedBox(key: Key('key2')),
          visible: true,
        );

        expect(child1, isNot(equals(child2)));
        expect(child1.hashCode, isNot(equals(child2.hashCode)));
      });

      test('instances with different child runtime types are not equal', () {
        const child1 = ResizableChild(
          id: 'test_id',
          child: SizedBox.shrink(),
          visible: true,
        );

        final child2 = ResizableChild(
          id: 'test_id',
          child: Container(),
          visible: true,
        );

        expect(child1, isNot(equals(child2)));
        expect(child1.hashCode, isNot(equals(child2.hashCode)));
      });

      test('instances with different keys are not equal', () {
        const child1 = ResizableChild(
          id: 'test_id',
          key: Key('key1'),
          child: SizedBox.shrink(),
          visible: true,
        );

        const child2 = ResizableChild(
          id: 'test_id',
          key: Key('key2'),
          child: SizedBox.shrink(),
          visible: true,
        );

        expect(child1, isNot(equals(child2)));
      });

      test('instances with null vs non-null keys are not equal', () {
        const child1 = ResizableChild(
          id: 'test_id',
          key: null,
          child: SizedBox.shrink(),
          visible: true,
        );

        const child2 = ResizableChild(
          id: 'test_id',
          key: Key('key'),
          child: SizedBox.shrink(),
          visible: true,
        );

        expect(child1, isNot(equals(child2)));
        expect(child1.hashCode, isNot(equals(child2.hashCode)));
      });

      test('instances with same null keys are equal', () {
        const child1 = ResizableChild(
          id: 'test_id',
          key: null,
          child: SizedBox.shrink(),
          visible: true,
        );

        const child2 = ResizableChild(
          id: 'test_id',
          key: null,
          child: SizedBox.shrink(),
          visible: true,
        );

        expect(child1, equals(child2));
        expect(child1.hashCode, equals(child2.hashCode));
      });

      test('stringify returns true', () {
        const child = ResizableChild(
          id: 'test_id',
          child: SizedBox.shrink(),
          visible: true,
        );

        expect(child.stringify, isTrue);
      });

      test('props includes all relevant properties', () {
        const child = ResizableChild(
          id: 'test_id',
          key: Key('test_key'),
          child: SizedBox.shrink(),
          size: ResizableSize.pixels(100),
          divider: ResizableDivider(thickness: 1),
          visible: false,
        );

        final props = child.props;

        expect(props, hasLength(5));
        expect(props, contains(child.size));
        expect(props, contains(child.key));
        expect(props, contains(child.child.key));
        expect(props, contains(child.child.runtimeType));
        expect(props, contains(child.visible));
      });
    });

    group('constructor', () {
      test('creates instance with default values', () {
        const child = ResizableChild(
          id: 'test_id',
          child: SizedBox.shrink(),
        );

        expect(child.id, equals('test_id'));
        expect(child.child.runtimeType, equals(SizedBox));
        expect(child.size, equals(const ResizableSize.expand()));
        expect(child.divider, equals(const ResizableDivider()));
        expect(child.visible, isTrue);
        expect(child.key, isNull);
      });

      test('creates instance with custom values', () {
        const customSize = ResizableSize.pixels(200);
        const customDivider = ResizableDivider(thickness: 2);
        const customKey = Key('custom_key');
        final customChild = Container();

        final child = ResizableChild(
          id: 'test_id',
          key: customKey,
          child: customChild,
          size: customSize,
          divider: customDivider,
          visible: false,
        );

        expect(child.id, equals('test_id'));
        expect(child.key, equals(customKey));
        expect(child.child, equals(customChild));
        expect(child.size, equals(customSize));
        expect(child.divider, equals(customDivider));
        expect(child.visible, isFalse);
      });
    });
  });
}

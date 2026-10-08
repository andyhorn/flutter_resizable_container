import 'package:flutter/widgets.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/layout/resizable_allocation.dart';
import 'package:flutter_test/flutter_test.dart';

ResizableChild _child({double thickness = 2, double padding = 0}) {
  return ResizableChild(
    divider: ResizableDivider(thickness: thickness, padding: padding),
    child: const SizedBox(),
  );
}

void main() {
  group('isDividerHidden', () {
    test('is false when no children are hidden', () {
      expect(isDividerHidden(const {}, 0), isFalse);
      expect(isDividerHidden(const {}, 1), isFalse);
    });

    test('is true when the child before the divider is hidden', () {
      expect(isDividerHidden(const {1}, 1), isTrue);
    });

    test('is true when the child after the divider is hidden', () {
      expect(isDividerHidden(const {1}, 0), isTrue);
    });

    test('is true for the divider next to a hidden first child', () {
      expect(isDividerHidden(const {0}, 0), isTrue);
      expect(isDividerHidden(const {0}, 1), isFalse);
    });

    test('is true for the divider next to a hidden last child', () {
      expect(isDividerHidden(const {2}, 1), isTrue);
      expect(isDividerHidden(const {2}, 0), isFalse);
    });

    test('is true for dividers between adjacent hidden children', () {
      const hidden = {1, 2};

      expect(isDividerHidden(hidden, 0), isTrue);
      expect(isDividerHidden(hidden, 1), isTrue);
      expect(isDividerHidden(hidden, 2), isTrue);
      expect(isDividerHidden(hidden, 3), isFalse);
    });
  });

  group('getDividerSpace', () {
    test('is 0 for an empty list', () {
      expect(getDividerSpace(const [], const {}), 0);
    });

    test('is 0 for a single child', () {
      expect(getDividerSpace([_child()], const {}), 0);
    });

    test('sums thickness of every divider when nothing is hidden', () {
      final children = [_child(), _child(thickness: 3), _child()];

      expect(getDividerSpace(children, const {}), 5);
    });

    test('adds padding to thickness', () {
      final children = [
        _child(thickness: 2, padding: 4),
        _child(thickness: 3, padding: 1),
        _child(thickness: 100, padding: 100),
      ];

      expect(getDividerSpace(children, const {}), 10);
    });

    test('ignores the divider after a hidden first child', () {
      final children = [_child(), _child(thickness: 3), _child()];

      expect(getDividerSpace(children, const {0}), 3);
    });

    test('ignores both dividers around a hidden middle child', () {
      final children = [_child(), _child(thickness: 3), _child()];

      expect(getDividerSpace(children, const {1}), 0);
    });

    test('ignores the divider before a hidden last child', () {
      final children = [_child(), _child(thickness: 3), _child()];

      expect(getDividerSpace(children, const {2}), 2);
    });

    test('ignores dividers around adjacent hidden children', () {
      final children = [_child(), _child(), _child(), _child(thickness: 7)];

      expect(getDividerSpace(children, const {1, 2}), 0);
    });

    test('is 0 when the only child is hidden', () {
      expect(getDividerSpace([_child()], const {0}), 0);
    });
  });
}

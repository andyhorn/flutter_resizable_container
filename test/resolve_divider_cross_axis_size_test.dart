import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(resolveDividerCrossAxisSize, () {
    test('expand returns the full cross-axis max', () {
      expect(
        resolveDividerCrossAxisSize(const ResizableSize.expand(), 200),
        200,
      );
    });

    test('ratio scales the cross-axis max', () {
      expect(
        resolveDividerCrossAxisSize(const ResizableSize.ratio(0.25), 200),
        50,
      );
    });

    test('pixels clamps to the cross-axis max', () {
      expect(
        resolveDividerCrossAxisSize(const ResizableSize.pixels(50), 200),
        50,
      );
      expect(
        resolveDividerCrossAxisSize(const ResizableSize.pixels(500), 200),
        200,
      );
    });

    test('shrink resolves to zero', () {
      expect(
        resolveDividerCrossAxisSize(const ResizableSize.shrink(), 200),
        0,
      );
    });
  });
}

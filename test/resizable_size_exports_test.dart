import 'package:flutter/widgets.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('exported ResizableSize subtypes', () {
    testWidgets('can be read from controller.sizes and switched on', (
      tester,
    ) async {
      final controller = ResizableController();
      addTearDown(controller.dispose);
      addTearDown(() => tester.pumpWidget(const SizedBox()));

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 800,
            height: 600,
            child: ResizableContainer(
              controller: controller,
              direction: Axis.horizontal,
              children: const [
                ResizableChild(
                  size: ResizableSize.pixels(100),
                  child: SizedBox.expand(),
                ),
                ResizableChild(
                  size: ResizableSize.ratio(0.5),
                  child: SizedBox.expand(),
                ),
                ResizableChild(
                  size: ResizableSize.expand(flex: 2),
                  child: SizedBox.expand(),
                ),
                ResizableChild(
                  size: ResizableSize.shrink(),
                  child: SizedBox(width: 10),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(controller.sizes, [
        isA<ResizableSizePixels>().having((s) => s.pixels, 'pixels', 100),
        isA<ResizableSizeRatio>().having((s) => s.ratio, 'ratio', 0.5),
        isA<ResizableSizeExpand>().having((s) => s.flex, 'flex', 2),
        isA<ResizableSizeShrink>(),
      ]);
    });
  });
}

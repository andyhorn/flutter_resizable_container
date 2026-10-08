import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'an animated show re-measures a shrink child whose content changed while '
    'it was hidden',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 400));
      final controller = ResizableController();
      final labelWidth = ValueNotifier<double>(100);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResizableContainer(
              controller: controller,
              direction: Axis.horizontal,
              hideAnimation: const ResizableHideAnimation(
                duration: Duration(milliseconds: 100),
                curve: Curves.linear,
              ),
              children: [
                ResizableChild(
                  size: const ResizableSize.shrink(),
                  child: ValueListenableBuilder<double>(
                    valueListenable: labelWidth,
                    builder: (_, width, __) => SizedBox(width: width),
                  ),
                ),
                const ResizableChild(child: SizedBox.expand()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.pixels.first, 100);

      controller.hide(0);
      await tester.pumpAndSettle();

      labelWidth.value = 160;
      controller.show(0);
      await tester.pumpAndSettle();

      expect(controller.pixels.first, 160);
    },
  );
}

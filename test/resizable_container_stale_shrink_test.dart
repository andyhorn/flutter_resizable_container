import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_test/flutter_test.dart';

class _ShrinkLabelApp extends StatelessWidget {
  const _ShrinkLabelApp({required this.controller, required this.labelWidth});

  final ResizableController controller;
  final ValueNotifier<double> labelWidth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}

void main() {
  testWidgets(
    'an animated show re-measures a shrink child whose content changed while '
    'it was hidden',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 400));
      final controller = ResizableController();
      final labelWidth = ValueNotifier<double>(100);

      await tester.pumpWidget(
        _ShrinkLabelApp(controller: controller, labelWidth: labelWidth),
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

  testWidgets(
    'a container disposed mid-show re-measures the shrink child on remount',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 400));
      final controller = ResizableController();
      addTearDown(controller.dispose);
      final labelWidth = ValueNotifier<double>(100);
      addTearDown(labelWidth.dispose);
      final app = _ShrinkLabelApp(
        controller: controller,
        labelWidth: labelWidth,
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      controller.hide(0);
      await tester.pumpAndSettle();

      labelWidth.value = 160;
      controller.show(0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(controller.pixels.first, 160);
    },
  );
}

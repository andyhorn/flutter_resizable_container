import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_test/flutter_test.dart';

class _SetSizesOnFirstFrame extends StatefulWidget {
  const _SetSizesOnFirstFrame({required this.controller});

  final ResizableController controller;

  @override
  State<_SetSizesOnFirstFrame> createState() => _SetSizesOnFirstFrameState();
}

class _SetSizesOnFirstFrameState extends State<_SetSizesOnFirstFrame> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.setSizes(const [
        ResizableSize.pixels(300),
        ResizableSize.expand(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResizableContainer(
      controller: widget.controller,
      direction: Axis.horizontal,
      children: const [
        ResizableChild(
          size: ResizableSize.pixels(100),
          child: ColoredBox(color: Color(0xFF0000FF)),
        ),
        ResizableChild(child: ColoredBox(color: Color(0xFFFF0000))),
      ],
    );
  }
}

void main() {
  testWidgets(
    'a setSizes call from an earlier post-frame callback is not overwritten '
    'by the first measurement',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 400));
      final controller = ResizableController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _SetSizesOnFirstFrame(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.pixels.first, 300);
    },
  );
}

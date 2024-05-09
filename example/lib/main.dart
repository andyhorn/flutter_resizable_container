import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';

const ratio1 = 0.75;
const ratio2 = 0.25;
const ratio3 = 0.5;
const ratio4 = 0.5;

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  bool hovered = false;
  bool hidden = false;

  final controller1 = ResizableController();
  final controller2 = ResizableController();

  Axis direction = Axis.horizontal;

  @override
  void initState() {
    super.initState();

    controller1.addListener(() {
      final sizes = controller1.sizes.map((size) => size.toStringAsFixed(2));

      debugPrint('Controller 1 sizes: ${sizes.join(', ')}');
    });

    controller2.addListener(() {
      final sizes = controller2.sizes.map((size) => size.toStringAsFixed(2));

      debugPrint('Controller 2 sizes: ${sizes.join(', ')}');
    });
  }

  @override
  void dispose() {
    controller1.dispose();
    controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Example ResizableContainer'),
          actions: [
            ElevatedButton(
              onPressed: () {
                controller1.ratios = [ratio1, ratio2];
                if (!hidden) {
                  controller2.ratios = [ratio3, ratio4];
                } else {
                  controller2.ratios = [null];
                }
              },
              child: const Text("Reset ratios"),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                final newDirection = direction == Axis.horizontal
                    ? Axis.vertical
                    : Axis.horizontal;

                setState(() => direction = newDirection);
              },
              child: direction == Axis.horizontal
                  ? const Text('Vertical')
                  : const Text('Horizontal'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => setState(() => hidden = !hidden),
              child: Text(hidden ? 'Show Child B' : 'Hide Child B'),
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: SafeArea(
          child: ResizableContainer(
            controller: controller1,
            direction: direction,
            divider: ResizableDivider(
              thickness: 3.0,
              size: 5.0,
              color: hovered ? Colors.orange : Colors.blue,
              indent: 12,
              endIndent: 12,
              onHoverEnter: () => setState(() => hovered = true),
              onHoverExit: () => setState(() => hovered = false),
            ),
            children: [
              ResizableChild(
                startingRatio: ratio1,
                minSize: 150,
                child: LayoutBuilder(
                  builder: (context, constraints) => Center(
                    child: direction == Axis.horizontal
                        ? Text(
                            'Left pane: ${constraints.maxHeight.toStringAsFixed(2)} x ${constraints.maxWidth.toStringAsFixed(2)}',
                            textAlign: TextAlign.center,
                          )
                        : Text(
                            'Top pane: ${constraints.maxHeight.toStringAsFixed(2)} x ${constraints.maxWidth.toStringAsFixed(2)}',
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
              ),
              ResizableChild(
                startingRatio: ratio2,
                maxSize: 500,
                child: ResizableContainer(
                  controller: controller2,
                  divider: const ResizableDivider(
                    color: Colors.green,
                  ),
                  direction: direction == Axis.horizontal
                      ? Axis.vertical
                      : Axis.horizontal,
                  children: [
                    ResizableChild(
                      startingRatio: ratio3,
                      child: LayoutBuilder(
                        builder: (context, constraints) => Center(
                          child: Text(
                            'Nested Child A: ${constraints.maxHeight.toStringAsFixed(2)} x ${constraints.maxWidth.toStringAsFixed(2)}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    if (!hidden) ...[
                      ResizableChild(
                        startingRatio: ratio4,
                        child: LayoutBuilder(
                          builder: (context, constraints) => Center(
                            child: Text(
                              'Nested Child B: ${constraints.maxHeight.toStringAsFixed(2)} x ${constraints.maxWidth.toStringAsFixed(2)}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

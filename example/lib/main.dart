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
  final controller1 = ResizableController(
    data: const [
      ResizableChildData(
        startingRatio: ratio1,
        minSize: 150,
      ),
      ResizableChildData(
        startingRatio: ratio2,
        maxSize: 500,
      ),
    ],
  );
  final controller2 = ResizableController(
    data: const [
      ResizableChildData(
        startingRatio: ratio3,
      ),
      ResizableChildData(
        startingRatio: ratio4,
      ),
    ],
  );

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
      theme: ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Example ResizableContainer'),
          actions: [
            ElevatedButton(
              onPressed: () {
                controller1.ratios = [ratio1, ratio2];
                controller2.ratios = [ratio3, ratio4];
              },
              child: const Text("Reset ratios"),
            ),
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
          ],
        ),
        body: SafeArea(
          child: ResizableContainer(
            controller: controller1,
            direction: direction,
            divider: const ResizableDivider(
              thickness: 3.0,
              size: 5.0,
              color: Colors.blue,
              indent: 12,
              endIndent: 12,
            ),
            children: [
              LayoutBuilder(
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
              ResizableContainer(
                controller: controller2,
                divider: const ResizableDivider(
                  color: Colors.green,
                ),
                direction: direction == Axis.horizontal
                    ? Axis.vertical
                    : Axis.horizontal,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) => Center(
                      child: Text(
                        'Nested Child A: ${constraints.maxHeight.toStringAsFixed(2)} x ${constraints.maxWidth.toStringAsFixed(2)}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) => Center(
                      child: Text(
                        'Nested Child B: ${constraints.maxHeight.toStringAsFixed(2)} x ${constraints.maxWidth.toStringAsFixed(2)}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

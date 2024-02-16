import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  Axis direction = Axis.horizontal;
  final controller1 = ResizableController();
  final controller2 = ResizableController();

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
                controller1.setRatios([0.75, 0.25]);
                controller2.setRatios([0.5, 0.5]);
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
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            child: const Icon(Icons.info),
            onPressed: () {
              final message = "Ratios: ${controller1.ratios.join(', ')} and ${controller2.ratios.join(', ')}";
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
            },
          ),
        ),
        body: SafeArea(
          child: ResizableContainer(
            controller: controller1,
            direction: direction,
            dividerWidth: 3.0,
            dividerColor: Colors.blue,
            children: [
              ResizableChildData(
                startingRatio: 0.75,
                minSize: 150,
                child: Center(
                  child: direction == Axis.horizontal
                      ? const Text('Left pane')
                      : const Text('Top pane'),
                ),
              ),
              ResizableChildData(
                startingRatio: 0.25,
                maxSize: 500,
                child: ResizableContainer(
                  controller: controller2,
                  dividerColor: Colors.green,
                  direction: direction == Axis.horizontal
                      ? Axis.vertical
                      : Axis.horizontal,
                  children: const [
                    ResizableChildData(
                      child: Center(
                        child: Text('Nested Child A'),
                      ),
                      startingRatio: 0.5,
                    ),
                    ResizableChildData(
                      child: Center(
                        child: Text('Nested Child B'),
                      ),
                      startingRatio: 0.5,
                    ),
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

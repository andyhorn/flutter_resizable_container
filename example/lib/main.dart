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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Example ResizableContainer'),
          actions: [
            MaterialButton(
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
            direction: direction,
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
                child: Center(
                  child: direction == Axis.horizontal
                      ? const Text('Right pane')
                      : const Text('Bottom pane'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Example ResizableContainer'),
          actions: [
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
                child: ResizableContainer(
                  dividerColor: Colors.blue,
                  dividerWidth: 8.0,
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

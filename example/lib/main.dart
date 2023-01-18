import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Example ResizableContainer'),
        ),
        body: ResizableContainer(
          direction: Axis.horizontal,
          children: const [
            ResizableChildData(
              startingRatio: 0.75,
              minSize: 150,
              child: Center(
                child: Text('Left pane'),
              ),
            ),
            ResizableChildData(
              startingRatio: 0.25,
              maxSize: 500,
              child: Center(
                child: Text('Right pane'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

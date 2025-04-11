import 'package:example/widgets/nav_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';

class FutureBuilderShrinkExampleScreen extends StatelessWidget {
  const FutureBuilderShrinkExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FutureBuilder shrink example'),
      ),
      drawer: const NavDrawer(),
      body: FutureBuilder(
        future: Future.delayed(const Duration(seconds: 1), () => 'Hello World'),
        builder: (context, snapshot) {
          return ResizableContainer(
            children: [
              ResizableChild(
                size: const ResizableSize.shrink(),
                child: switch (snapshot.connectionState) {
                  ConnectionState.done => Text(
                      snapshot.data!,
                      key: UniqueKey(),
                    ),
                  _ => const SizedBox.shrink(),
                },
              ),
              const ResizableChild(
                child: SizedBox.expand(child: Text('Right')),
              ),
            ],
            direction: Axis.horizontal,
          );
        },
      ),
    );
  }
}

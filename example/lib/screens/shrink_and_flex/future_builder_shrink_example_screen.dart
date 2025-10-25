import 'package:example/widgets/nav_drawer.dart';
import 'package:example/widgets/size_label.dart';
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
        future: Future.delayed(
          const Duration(seconds: 3),
          () => 'Future/Stream Content',
        ),
        builder: (context, snapshot) {
          return ResizableContainer(
            children: [
              ResizableChild(
                id: 'child_24',
                size: const ResizableSize.shrink(),
                child: switch (snapshot.connectionState) {
                  ConnectionState.done => ColoredBox(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Center(child: Text(snapshot.data!)),
                      ),
                    ),
                  _ => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        child: SizedBox.square(
                          dimension: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    ),
                },
              ),
              ResizableChild(
                id: 'child_53',
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: const SizeLabel(),
                ),
              ),
            ],
            direction: Axis.horizontal,
          );
        },
      ),
    );
  }
}

import 'package:example/screens/ratio/ratio_example_help_dialog.dart';
import 'package:example/widgets/nav_drawer.dart';
import 'package:example/widgets/size_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';

class RatioExampleScreen extends StatelessWidget {
  const RatioExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ratio example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_center),
            onPressed: () => RatioExampleHelpDialog.show(context: context),
          ),
        ],
      ),
      drawer: const NavDrawer(),
      body: ResizableContainer(
        direction: Axis.horizontal,
        children: [
          ResizableChild(
            size: const ResizableSize.ratio(0.15),
            child: ColoredBox(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const SizeLabel(),
            ),
          ),
          ResizableChild(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: const SizeLabel(),
            ),
          ),
          ResizableChild(
            size: const ResizableSize.ratio(0.15),
            child: ColoredBox(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const SizeLabel(),
            ),
          ),
        ],
      ),
    );
  }
}

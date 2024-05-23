import 'package:example/screens/controller_set_sizes/controller_set_sizes_example_help_dialog.dart';
import 'package:example/widgets/code_view_dialog.dart';
import 'package:example/widgets/nav_drawer.dart';
import 'package:example/widgets/size_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';

class ControllerSetSizesExampleScreen extends StatefulWidget {
  const ControllerSetSizesExampleScreen({super.key});

  @override
  State<ControllerSetSizesExampleScreen> createState() =>
      _ControllerSetSizesExampleScreenState();
}

class _ControllerSetSizesExampleScreenState
    extends State<ControllerSetSizesExampleScreen> {
  final controller = ResizableController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controller set sizes example'),
        actions: [
          PopupMenuButton(
            color: Theme.of(context).colorScheme.primaryContainer,
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'ratios',
                  child: Text('Ratios'),
                ),
                PopupMenuItem(
                  value: 'pixels',
                  child: Text('Pixels'),
                ),
                PopupMenuItem(
                  value: 'flex',
                  child: Text('Flex'),
                ),
              ];
            },
            onSelected: (code) {
              switch (code) {
                case 'ratios':
                  controller.setSizes(const [
                    ResizableSize.ratio(0.5),
                    ResizableSize.ratio(0.2),
                    ResizableSize.ratio(0.3),
                  ]);
                case 'pixels':
                  const numDividers = 2;
                  const dividerWidth = 2;
                  final availableSpace = MediaQuery.sizeOf(context).width -
                      (numDividers * dividerWidth);
                  final quarterSpace = availableSpace / 4;
                  controller.setSizes([
                    ResizableSize.pixels(quarterSpace),
                    ResizableSize.pixels(quarterSpace * 2),
                    ResizableSize.pixels(quarterSpace),
                  ]);
                case 'flex':
                  controller.setSizes(const [
                    ResizableSize.expand(),
                    ResizableSize.expand(flex: 3),
                    ResizableSize.expand(flex: 2),
                  ]);
              }
            },
            icon: const Icon(Icons.shape_line),
          ),
          IconButton(
            onPressed: () => ControllerSetSizesExampleHelpDialog.show(
              context: context,
            ),
            icon: const Icon(Icons.help_center),
          ),
          IconButton(
            onPressed: () => CodeViewDialog.show(
              context: context,
              filePath:
                  'lib/screens/controller_set_sizes/controller_set_sizes_example_screen.dart',
            ),
            icon: const Icon(Icons.code),
          ),
        ],
      ),
      drawer: const NavDrawer(),
      body: ResizableContainer(
        controller: controller,
        direction: Axis.horizontal,
        children: [
          ResizableChild(
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
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: const SizeLabel(),
            ),
          ),
        ],
      ),
    );
  }
}

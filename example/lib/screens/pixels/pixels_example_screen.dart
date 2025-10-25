import 'package:example/file_asset_paths.dart';
import 'package:example/screens/pixels/pixels_example_help_dialog.dart';
import 'package:example/widgets/code_view_dialog.dart';
import 'package:example/widgets/nav_drawer.dart';
import 'package:example/widgets/size_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';

class PixelsExampleScreen extends StatelessWidget {
  const PixelsExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pixels example'),
        actions: [
          IconButton(
            onPressed: () => PixelsExampleHelpDialog.show(context: context),
            icon: const Icon(Icons.help_center),
          ),
          IconButton(
            onPressed: () => CodeViewDialog.show(
              context: context,
              filePath: FileAssetPaths.pixelsScreen,
            ),
            icon: const Icon(Icons.code),
          ),
        ],
      ),
      drawer: const NavDrawer(),
      body: ResizableContainer(
        direction: Axis.horizontal,
        children: [
          ResizableChild(
            id: 'child_35',
            size: const ResizableSize.pixels(333),
            child: ColoredBox(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const SizeLabel(),
            ),
          ),
          ResizableChild(
            id: 'child_42',
            child: ColoredBox(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: const SizeLabel(),
            ),
          ),
        ],
      ),
    );
  }
}

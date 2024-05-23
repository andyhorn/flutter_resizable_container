import 'package:example/file_asset_paths.dart';
import 'package:example/screens/basic/basic_example_help_dialog.dart';
import 'package:example/widgets/code_view_dialog.dart';
import 'package:example/widgets/nav_drawer.dart';
import 'package:example/widgets/size_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';

class BasicExampleScreen extends StatelessWidget {
  const BasicExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic two-pane example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_center),
            onPressed: () => BasicExampleHelpDialog.show(context: context),
          ),
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: () => CodeViewDialog.show(
              context: context,
              filePath: FileAssetPaths.basicScreen,
            ),
          ),
        ],
      ),
      drawer: const NavDrawer(),
      body: ResizableContainer(
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
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: const SizeLabel(),
            ),
          ),
        ],
      ),
    );
  }
}

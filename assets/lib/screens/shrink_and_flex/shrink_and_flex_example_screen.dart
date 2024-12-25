import 'package:example/file_asset_paths.dart';
import 'package:example/screens/shrink_and_flex/shrink_and_flex_help_dialog.dart';
import 'package:example/widgets/code_view_dialog.dart';
import 'package:example/widgets/nav_drawer.dart';
import 'package:example/widgets/size_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';

class ShrinkAndFlexExampleScreen extends StatefulWidget {
  const ShrinkAndFlexExampleScreen({super.key});

  @override
  State<ShrinkAndFlexExampleScreen> createState() =>
      _ShrinkAndFlexExampleScreenState();
}

class _ShrinkAndFlexExampleScreenState
    extends State<ShrinkAndFlexExampleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shrink and flex example'),
        actions: [
          IconButton(
            onPressed: () => ShrinkAndFlexHelpDialog.show(context: context),
            icon: const Icon(Icons.help_center),
          ),
          IconButton(
            onPressed: () => CodeViewDialog.show(
              context: context,
              filePath: FileAssetPaths.shrinkAndFlexScreen,
            ),
            icon: const Icon(Icons.code),
          ),
        ],
      ),
      drawer: const NavDrawer(),
      body: Column(
        children: [
          Expanded(
            child: ResizableContainer(
              direction: Axis.horizontal,
              children: [
                ResizableChild(
                  size: const ResizableSize.expand(),
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: const SizeLabel(),
                  ),
                ),
                ResizableChild(
                  size: const ResizableSize.shrink(),
                  child: SizedBox(
                    width: 100,
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      child: const SizeLabel(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

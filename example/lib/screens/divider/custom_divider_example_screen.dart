import 'package:example/file_asset_paths.dart';
import 'package:example/widgets/code_view_dialog.dart';
import 'package:example/widgets/nav_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';

class CustomDividerExampleScreen extends StatefulWidget {
  const CustomDividerExampleScreen({super.key});

  @override
  State<CustomDividerExampleScreen> createState() =>
      _CustomDividerExampleScreenState();
}

class _CustomDividerExampleScreenState
    extends State<CustomDividerExampleScreen> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom divider example'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => CodeViewDialog.show(
              context: context,
              filePath: FileAssetPaths.dividerScreen,
            ),
            icon: const Icon(Icons.code),
          ),
        ],
      ),
      drawer: const NavDrawer(),
      body: ResizableContainer(
        direction: Axis.horizontal,
        divider: ResizableDivider(
          color: hovered
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.inversePrimary,
          thickness: 4,
          padding: 10,
          length: const ResizableSize.ratio(0.2),
          onHoverEnter: () => setState(() => hovered = true),
          onHoverExit: () => setState(() => hovered = false),
        ),
        children: [
          ResizableChild(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const Center(child: Text('Left')),
            ),
          ),
          ResizableChild(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: const Center(child: Text('Right')),
            ),
          ),
        ],
      ),
    );
  }
}

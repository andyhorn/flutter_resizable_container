import 'package:example/file_asset_paths.dart';
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
            onPressed: () => CodeViewDialog.show(
              context: context,
              filePath: FileAssetPaths.controllerListenScreen,
            ),
            icon: const Icon(Icons.code),
          ),
        ],
      ),
      drawer: const NavDrawer(),
      body: const Column(
        children: [
          Expanded(
            child: ResizableContainer(
              direction: Axis.horizontal,
              children: [
                ResizableChild(
                  size: ResizableSize.expand(),
                  child: ColoredBox(
                    color: Colors.pink,
                    child: SizeLabel(),
                  ),
                ),
                ResizableChild(
                  size: ResizableSize.shrink(),
                  child: ColoredBox(
                    color: Colors.blue,
                    child: SizeLabel(),
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

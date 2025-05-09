import 'package:example/file_asset_paths.dart';
import 'package:example/widgets/code_view_dialog.dart';
import 'package:example/widgets/nav_drawer.dart';
import 'package:example/widgets/size_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';

class CascadingDeltaScreen extends StatefulWidget {
  const CascadingDeltaScreen({super.key});

  @override
  State<CascadingDeltaScreen> createState() => _CascadingDeltaScreenState();
}

class _CascadingDeltaScreenState extends State<CascadingDeltaScreen> {
  var cascade = false;

  @override
  Widget build(BuildContext context) {
    const size = ResizableSize.expand(min: 50);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic two-pane example'),
        actions: [
          Row(
            children: [
              const Text('Cascade'),
              const SizedBox(width: 8),
              Switch(
                value: cascade,
                onChanged: (cascade) => setState(() => this.cascade = cascade),
              ),
            ],
          ),
          // IconButton(
          //   icon: const Icon(Icons.help_center),
          //   onPressed: () => BasicExampleHelpDialog.show(context: context),
          // ),
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: () => CodeViewDialog.show(
              context: context,
              filePath: FileAssetPaths.cascadingDeltaScreen,
            ),
          ),
        ],
      ),
      drawer: const NavDrawer(),
      body: ResizableContainer(
        direction: Axis.horizontal,
        cascadeNegativeDelta: cascade,
        children: [
          ResizableChild(
            size: size,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const SizeLabel(),
            ),
          ),
          ResizableChild(
            size: size,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: const SizeLabel(),
            ),
          ),
          ResizableChild(
            size: size,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const SizeLabel(),
            ),
          ),
          ResizableChild(
            size: size,
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

import 'package:example/file_asset_paths.dart';
import 'package:example/widgets/code_view_dialog.dart';
import 'package:example/widgets/nav_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';

class ShrinkScrollableExampleScreen extends StatefulWidget {
  const ShrinkScrollableExampleScreen({super.key});

  @override
  State<ShrinkScrollableExampleScreen> createState() =>
      _ShrinkScrollableExampleScreenState();
}

class _ShrinkScrollableExampleScreenState
    extends State<ShrinkScrollableExampleScreen> {
  int _rowCount = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shrink with scrollable content'),
        actions: [
          IconButton(
            onPressed: () => CodeViewDialog.show(
              context: context,
              filePath: FileAssetPaths.shrinkScrollableScreen,
            ),
            icon: const Icon(Icons.code),
          ),
        ],
      ),
      drawer: const NavDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: () => setState(() => _rowCount += 1),
                  child: const Text('Add row'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _rowCount > 0
                      ? () => setState(() => _rowCount -= 1)
                      : null,
                  child: const Text('Remove row'),
                ),
                const SizedBox(width: 16),
                Text('Rows: $_rowCount'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ResizableContainer(
                direction: Axis.vertical,
                children: [
                  ResizableChild(
                    size: const ResizableSize.shrink(),
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < _rowCount; i++)
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text('Row ${i + 1}'),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ResizableChild(
                    size: const ResizableSize.expand(),
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: const Center(
                        child: Text('Expanding sibling fills the rest'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

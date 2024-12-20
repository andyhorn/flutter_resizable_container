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
  var hovered = false;
  var length = 0.5;
  var thickness = 2.0;
  var padding = 5.0;
  var crossAxisAlignment = CrossAxisAlignment.center;
  var mainAxisAlignment = MainAxisAlignment.center;

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
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  const Text('Length'),
                  Slider(
                    min: 0.01,
                    max: 1.0,
                    value: length,
                    onChanged: (value) => setState(() => length = value),
                  ),
                  Text('Ratio: ${(length * 100).toStringAsFixed((2))}%'),
                ],
              ),
              Column(
                children: [
                  const Text('Thickness'),
                  Slider(
                    min: 1,
                    max: 20.0,
                    divisions: 19,
                    value: thickness,
                    onChanged: (value) => setState(() => thickness = value),
                  ),
                  Text('${thickness}px'),
                ],
              ),
              Column(
                children: [
                  const Text('Padding'),
                  Slider(
                    min: 0,
                    max: 20,
                    divisions: 20,
                    value: padding,
                    onChanged: (value) => setState(() => padding = value),
                  ),
                  Text('${padding}px'),
                ],
              ),
              Column(
                children: [
                  const Text('Cross-Axis Alignment'),
                  DropdownButton(
                    value: crossAxisAlignment,
                    items: const [
                      DropdownMenuItem(
                        value: CrossAxisAlignment.start,
                        child: Text('Start'),
                      ),
                      DropdownMenuItem(
                        value: CrossAxisAlignment.center,
                        child: Text('Center'),
                      ),
                      DropdownMenuItem(
                        value: CrossAxisAlignment.end,
                        child: Text('End'),
                      ),
                    ],
                    onChanged: (value) => setState(
                      () => crossAxisAlignment = value!,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('Main-Axis Alignment'),
                  DropdownButton(
                    value: mainAxisAlignment,
                    items: const [
                      DropdownMenuItem(
                        value: MainAxisAlignment.start,
                        child: Text('Start'),
                      ),
                      DropdownMenuItem(
                        value: MainAxisAlignment.center,
                        child: Text('Center'),
                      ),
                      DropdownMenuItem(
                        value: MainAxisAlignment.end,
                        child: Text('End'),
                      ),
                    ],
                    onChanged: (value) => setState(
                      () => mainAxisAlignment = value!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ResizableContainer(
              direction: Axis.horizontal,
              children: [
                ResizableChild(
                  divider: ResizableDivider(
                    color: hovered
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.inversePrimary,
                    thickness: thickness,
                    padding: padding,
                    crossAxisAlignment: crossAxisAlignment,
                    mainAxisAlignment: mainAxisAlignment,
                    length: ResizableSize.ratio(length),
                    onHoverEnter: () => setState(() => hovered = true),
                    onHoverExit: () => setState(() => hovered = false),
                    onTapDown: () => setState(() => hovered = true),
                    onTapUp: () => setState(() => hovered = false),
                  ),
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
          ),
        ],
      ),
    );
  }
}

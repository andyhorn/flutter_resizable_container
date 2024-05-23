import 'package:example/screens/controller_listen/controller_listen_example_help_dialog.dart';
import 'package:example/widgets/code_view_dialog.dart';
import 'package:example/widgets/nav_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';

class ControllerListenExampleScreen extends StatefulWidget {
  const ControllerListenExampleScreen({super.key});

  @override
  State<ControllerListenExampleScreen> createState() =>
      _ControllerListenExampleScreenState();
}

class _ControllerListenExampleScreenState
    extends State<ControllerListenExampleScreen> {
  final controller = ResizableController();

  double? leftWidth;
  double? rightWidth;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      final sizes = controller.sizes;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          leftWidth = sizes.first;
          rightWidth = sizes.last;
        });
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controller listen example'),
        actions: [
          IconButton(
            onPressed: () => ControllerListenExampleHelpDialog.show(
              context: context,
            ),
            icon: const Icon(Icons.help_center),
          ),
          IconButton(
            onPressed: () => CodeViewDialog.show(
              context: context,
              filePath:
                  'lib/screens/controller_listen/controller_listen_example_screen.dart',
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
              controller: controller,
              direction: Axis.horizontal,
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
          ),
          Builder(builder: (context) {
            final left = leftWidth;
            final right = rightWidth;

            if (left == null || right == null) {
              return const SizedBox.shrink();
            }

            final leftLabel = left.toStringAsFixed(2);
            final rightLabel = right.toStringAsFixed(2);
            final totalSpace = left + right;
            final totalSpaceLabel = totalSpace.toStringAsFixed(2);

            return Text(
              'Left: $leftLabel | Right: $rightLabel | Total: $totalSpaceLabel',
            );
          }),
        ],
      ),
    );
  }
}

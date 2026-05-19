import 'package:example/file_asset_paths.dart';
import 'package:example/widgets/code_view_dialog.dart';
import 'package:example/widgets/nav_drawer.dart';
import 'package:example/widgets/size_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';

class HideShowExampleScreen extends StatefulWidget {
  const HideShowExampleScreen({super.key});

  @override
  State<HideShowExampleScreen> createState() => _HideShowExampleScreenState();
}

class _HideShowExampleScreenState extends State<HideShowExampleScreen> {
  static const _leftIndex = 0;
  static const _rightIndex = 2;

  final controller = ResizableController();

  bool _animate = true;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final leftHidden = controller.isHidden(_leftIndex);
    final rightHidden = controller.isHidden(_rightIndex);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hide / Show example'),
        actions: [
          IconButton(
            tooltip: _animate
                ? 'Animated hide/show is on'
                : 'Animated hide/show is off',
            onPressed: () => setState(() => _animate = !_animate),
            icon: Icon(
              _animate ? Icons.animation : Icons.flash_on,
            ),
          ),
          IconButton(
            tooltip: leftHidden ? 'Show left panel' : 'Hide left panel',
            onPressed: () => controller.setHidden(_leftIndex, !leftHidden),
            icon: Icon(
              leftHidden ? Icons.first_page : Icons.last_page,
            ),
          ),
          IconButton(
            tooltip: rightHidden ? 'Show right panel' : 'Hide right panel',
            onPressed: () => controller.setHidden(_rightIndex, !rightHidden),
            icon: Icon(
              rightHidden ? Icons.last_page : Icons.first_page,
            ),
          ),
          IconButton(
            tooltip: 'Resize left to 320px (works while hidden)',
            onPressed: () => controller.setSizes([
              const ResizableSize.pixels(320),
              const ResizableSize.expand(),
              ResizableSize.pixels(controller.pixels[2]),
            ]),
            icon: const Icon(Icons.straighten),
          ),
          IconButton(
            onPressed: () => CodeViewDialog.show(
              context: context,
              filePath: FileAssetPaths.hideShowScreen,
            ),
            icon: const Icon(Icons.code),
          ),
        ],
      ),
      drawer: const NavDrawer(),
      body: ResizableContainer(
        controller: controller,
        direction: Axis.horizontal,
        hideAnimation: _animate ? const ResizableHideAnimation() : null,
        children: [
          ResizableChild(
            size: const ResizableSize.pixels(240),
            child: ColoredBox(
              color: colors.primaryContainer,
              child: const _PanelLabel(title: 'Explorer'),
            ),
          ),
          ResizableChild(
            size: const ResizableSize.expand(),
            child: ColoredBox(
              color: colors.surfaceContainer,
              child: const _PanelLabel(title: 'Editor'),
            ),
          ),
          ResizableChild(
            size: const ResizableSize.pixels(200),
            child: ColoredBox(
              color: colors.tertiaryContainer,
              child: const _PanelLabel(title: 'Outline'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelLabel extends StatelessWidget {
  const _PanelLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const SizeLabel(),
      ],
    );
  }
}

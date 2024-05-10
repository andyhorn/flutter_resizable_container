import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:package_info_plus/package_info_plus.dart';

const ratio1 = 0.75;
const ratio2 = 0.25;
const ratio3 = 0.5;
const ratio4 = 0.5;

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final controller1 = ResizableController();
  final controller2 = ResizableController();

  bool hovered = false;
  bool hidden = false;
  bool expand = true;
  Axis direction = Axis.horizontal;

  @override
  void initState() {
    super.initState();

    controller1.addListener(() {
      final sizes = controller1.sizes.map((size) => size.toStringAsFixed(2));

      debugPrint('Controller 1 sizes: ${sizes.join(', ')}');
    });

    controller2.addListener(() {
      final sizes = controller2.sizes.map((size) => size.toStringAsFixed(2));

      debugPrint('Controller 2 sizes: ${sizes.join(', ')}');
    });
  }

  @override
  void dispose() {
    controller1.dispose();
    controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Example ResizableContainer'),
          actions: [
            ElevatedButton(
              onPressed: () {
                controller1.ratios = [ratio1, ratio2];
                if (!hidden) {
                  controller2.ratios = [ratio3, ratio4];
                } else {
                  controller2.ratios = [null];
                }
              },
              child: const Text("Reset ratios"),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                final newDirection = direction == Axis.horizontal
                    ? Axis.vertical
                    : Axis.horizontal;

                setState(() => direction = newDirection);
              },
              child: direction == Axis.horizontal
                  ? const Text('Vertical')
                  : const Text('Horizontal'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => setState(() => hidden = !hidden),
              child: Text(hidden ? 'Show Child B' : 'Hide Child B'),
            ),
            const SizedBox(width: 10),
            const Text('Auto-expand?'),
            Switch(
              value: expand,
              onChanged: (_) => setState(() => expand = !expand),
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ResizableContainer(
                  controller: controller1,
                  direction: direction,
                  divider: ResizableDivider(
                    thickness: 3.0,
                    size: 5.0,
                    color: hovered ? Colors.orange : Colors.blue,
                    indent: 12,
                    endIndent: 12,
                    onHoverEnter: () => setState(() => hovered = true),
                    onHoverExit: () => setState(() => hovered = false),
                  ),
                  children: [
                    ResizableChild(
                      startingRatio: ratio1,
                      minSize: 150,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return ExpandedChild(
                            color: Colors.green,
                            constraints: constraints,
                            label: direction == Axis.horizontal
                                ? 'Left Pane'
                                : 'Right Pane',
                          );
                        },
                      ),
                    ),
                    ResizableChild(
                      startingRatio: ratio2,
                      maxSize: 500,
                      child: ResizableContainer(
                        controller: controller2,
                        divider: const ResizableDivider(
                          color: Colors.green,
                        ),
                        direction: direction == Axis.horizontal
                            ? Axis.vertical
                            : Axis.horizontal,
                        children: [
                          ResizableChild(
                            expand: expand,
                            startingRatio: ratio3,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return ExpandedChild(
                                  color: Colors.pink,
                                  constraints: constraints,
                                  label: 'Nested Child A',
                                );
                              },
                            ),
                          ),
                          if (!hidden) ...[
                            ResizableChild(
                              startingRatio: ratio4,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return ExpandedChild(
                                    label: 'Nested Child B',
                                    color: Colors.amber,
                                    constraints: constraints,
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              FutureBuilder(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final data = snapshot.data!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 1,
                        horizontal: 8,
                      ),
                      child: Text('v${data.version}'),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpandedChild extends StatelessWidget {
  const ExpandedChild({
    super.key,
    required this.color,
    required this.constraints,
    required this.label,
  });

  final Color color;
  final BoxConstraints constraints;
  final String label;

  @override
  Widget build(BuildContext context) {
    final height = constraints.maxHeight.toStringAsFixed(2);
    final width = constraints.maxWidth.toStringAsFixed(2);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
      ),
      child: SizedBox.expand(
        child: Center(
          child: Text(
            '$label ($height x $width)',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

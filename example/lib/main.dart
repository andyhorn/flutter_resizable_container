import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:package_info_plus/package_info_plus.dart';

const rightPanelRatio = 0.25;

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
      final ratios = controller1.ratios.map(
        (ratio) => ratio.toStringAsFixed(2),
      );

      debugPrint('Controller 1 sizes: ${sizes.join(', ')}');
      debugPrint('Controller 1 ratios: ${ratios.join(', ')}');
    });

    controller2.addListener(() {
      final sizes = controller2.sizes.map((size) => size.toStringAsFixed(2));
      final ratios = controller2.ratios.map(
        (ratio) => ratio.toStringAsFixed(2),
      );

      debugPrint('Controller 2 sizes: ${sizes.join(', ')}');
      debugPrint('Controller 2 ratios: ${ratios.join(', ')}');
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
      title: 'ResizableContainer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Example ResizableContainer'),
          actions: [
            ElevatedButton(
              onPressed: () {
                controller1.setSizes(const [
                  ResizableSize.expand(),
                  ResizableSize.ratio(rightPanelRatio),
                ]);

                controller2.setSizes([
                  const ResizableSize.expand(flex: 2),
                  if (!hidden) ...[
                    const ResizableSize.expand(),
                  ],
                ]);
              },
              child: const Text("Reset sizes"),
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
                      size: const ResizableSize.expand(),
                      minSize: 150,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final pane = switch (direction) {
                            Axis.horizontal => 'Left Pane',
                            Axis.vertical => 'Top Pane',
                          };

                          return DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            ),
                            child: SizedBox.expand(
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        pane,
                                        textAlign: TextAlign.center,
                                      ),
                                      ConstraintsLabel(
                                        constraints: constraints,
                                      ),
                                    ],
                                  ),
                                  if (direction == Axis.horizontal) ...[
                                    const Align(
                                      alignment: Alignment.topCenter,
                                      child: Text(
                                        'expand()',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ] else ...[
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Transform.translate(
                                        offset: const Offset(-35, -35),
                                        child: Transform.rotate(
                                          angle: -pi / 2,
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            'expand()',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    ResizableChild(
                      size: const ResizableSize.ratio(rightPanelRatio),
                      maxSize: 500,
                      child: ResizableContainer(
                        controller: controller2,
                        divider: const ResizableDivider(
                          color: Colors.green,
                        ),
                        direction: switch (direction) {
                          Axis.vertical => Axis.horizontal,
                          Axis.horizontal => Axis.vertical,
                        },
                        children: [
                          ResizableChild(
                            size: const ResizableSize.expand(flex: 2),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final pane = switch (direction) {
                                  Axis.horizontal => 'Top Right',
                                  Axis.vertical => 'Bottom Left',
                                };

                                return DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                  ),
                                  child: SizedBox.expand(
                                    child: Stack(
                                      children: [
                                        if (direction == Axis.horizontal) ...[
                                          const Align(
                                            alignment: Alignment.topCenter,
                                            child: Text(
                                              'ratio(0.25)',
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ] else ...[
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Transform.translate(
                                              offset: const Offset(-50, -35),
                                              child: Transform.rotate(
                                                angle: -pi / 2,
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text(
                                                  'ratio(0.25)',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelLarge,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              pane,
                                              textAlign: TextAlign.center,
                                            ),
                                            ConstraintsLabel(
                                              constraints: constraints,
                                            ),
                                          ],
                                        ),
                                        if (direction == Axis.horizontal) ...[
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Transform.translate(
                                              offset: const Offset(-10, 50),
                                              child: Transform.rotate(
                                                angle: pi / 2,
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text(
                                                  'expand(flex: 2)',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelLarge,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ] else ...[
                                          const Align(
                                            alignment: Alignment.topCenter,
                                            child: Text('expand(flex: 2)'),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (!hidden) ...[
                            ResizableChild(
                              size: const ResizableSize.expand(),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiaryContainer,
                                    ),
                                    child: SizedBox.expand(
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Text('Bottom Right'),
                                                ConstraintsLabel(
                                                  constraints: constraints,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (direction == Axis.horizontal) ...[
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: Transform.translate(
                                                offset: const Offset(-10, 30),
                                                child: Transform.rotate(
                                                  angle: pi / 2,
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                    'expand()',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelLarge,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ] else ...[
                                            const Align(
                                              alignment: Alignment.topCenter,
                                              child: Text('expand()'),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
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

class ConstraintsLabel extends StatelessWidget {
  const ConstraintsLabel({super.key, required this.constraints});

  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final height = constraints.maxHeight.toStringAsFixed(2);
    final width = constraints.maxWidth.toStringAsFixed(2);

    return Text(
      'Height: $height px\nWidth: $width px',
      textAlign: TextAlign.center,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
      ),
      child: SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, textAlign: TextAlign.center),
            ConstraintsLabel(constraints: constraints),
          ],
        ),
      ),
    );
  }
}

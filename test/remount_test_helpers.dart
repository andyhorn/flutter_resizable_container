import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_test/flutter_test.dart';

class RemountProbe extends StatefulWidget {
  const RemountProbe({super.key, required this.name, required this.inits});

  final String name;
  final Map<String, int> inits;

  @override
  State<RemountProbe> createState() => RemountProbeState();
}

class RemountProbeState extends State<RemountProbe> {
  @override
  void initState() {
    super.initState();
    widget.inits.update(widget.name, (count) => count + 1, ifAbsent: () => 1);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

const hideAnimation = ResizableHideAnimation(
  duration: Duration(milliseconds: 200),
);

List<ResizableChild> buildChildren(
  Map<String, int> inits, {
  bool keyed = true,
  ResizableDivider divider = const ResizableDivider(thickness: 2),
  List<String> names = const ['A', 'B', 'C'],
}) {
  return [
    for (var i = 0; i < names.length; i++)
      ResizableChild(
        key: keyed ? ValueKey(names[i]) : null,
        size: i < 2
            ? const ResizableSize.pixels(150)
            : const ResizableSize.expand(),
        divider: divider,
        child: RemountProbe(name: names[i], inits: inits),
      ),
  ];
}

Widget buildHarness({
  required ResizableController controller,
  required List<ResizableChild> children,
  Axis direction = Axis.horizontal,
  ResizableHideAnimation? hideAnimation,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return MaterialApp(
    builder: (context, child) =>
        Directionality(textDirection: textDirection, child: child!),
    home: Scaffold(
      body: ResizableContainer(
        controller: controller,
        direction: direction,
        hideAnimation: hideAnimation,
        children: children,
      ),
    ),
  );
}

Future<void> useSurface(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

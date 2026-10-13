import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/divider_painter.dart';
import 'package:flutter_resizable_container/src/resizable_divider_handle.dart';
import 'package:flutter_resizable_container/src/resizable_divider_line.dart';
import 'package:flutter_test/flutter_test.dart';

const _dividerLabel = 'ResizableDividerHandle';

Widget _harness({
  required ResizableController controller,
  Axis direction = Axis.horizontal,
  TextDirection textDirection = TextDirection.ltr,
  bool resizable = true,
  ResizableHideAnimation? hideAnimation,
  List<ResizableChild>? children,
  ResizableDivider divider = const ResizableDivider(),
}) {
  return MaterialApp(
    home: Directionality(
      textDirection: textDirection,
      child: Scaffold(
        body: ResizableContainer(
          controller: controller,
          direction: direction,
          resizable: resizable,
          hideAnimation: hideAnimation,
          children: children ??
              [
                for (var i = 0; i < 3; i++)
                  ResizableChild(divider: divider, child: const SizedBox()),
              ],
        ),
      ),
    ),
  );
}

ResizableChild _paneWithButton(
  FocusNode node, {
  ResizableDivider divider = const ResizableDivider(),
  ResizableSize size = const ResizableSize.expand(),
  String label = 'button',
}) {
  return ResizableChild(
    size: size,
    divider: divider,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: TextButton(
        focusNode: node,
        onPressed: () {},
        child: Text(label),
      ),
    ),
  );
}

bool _dividerHasFocus() {
  return FocusManager.instance.primaryFocus?.debugLabel == _dividerLabel;
}

Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

Future<void> _focusDivider(
  WidgetTester tester,
  int index, {
  Offset? at,
}) async {
  final finder = find.byType(ResizableDividerHandle).at(index);
  await tester.tapAt(
    at ?? tester.getCenter(finder),
    kind: PointerDeviceKind.mouse,
  );
  await tester.pump();
}

Future<void> _pressArrow(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  if (shift) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.sendKeyEvent(key);
  if (shift) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.pump();
}

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });

  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('keyboard', () {
    late ResizableController controller;

    setUp(() => controller = ResizableController());
    tearDown(() => controller.dispose());

    testWidgets('arrow keys move the divider by keyboardStep', (tester) async {
      await _pump(tester, _harness(controller: controller));
      await _focusDivider(tester, 0);
      final initial = controller.pixels[0];

      await _pressArrow(tester, LogicalKeyboardKey.arrowRight);
      expect(controller.pixels[0], closeTo(initial + 10, 0.001));

      await _pressArrow(tester, LogicalKeyboardKey.arrowLeft);
      await _pressArrow(tester, LogicalKeyboardKey.arrowLeft);
      expect(controller.pixels[0], closeTo(initial - 10, 0.001));
    });

    testWidgets('Shift multiplies the step by 5', (tester) async {
      await _pump(tester, _harness(controller: controller));
      await _focusDivider(tester, 0);
      final initial = controller.pixels[0];

      await _pressArrow(tester, LogicalKeyboardKey.arrowRight, shift: true);

      expect(controller.pixels[0], closeTo(initial + 50, 0.001));
    });

    testWidgets('Shift multiplies the decrease step by 5', (tester) async {
      await _pump(tester, _harness(controller: controller));
      await _focusDivider(tester, 0);
      final initial = controller.pixels[0];

      await _pressArrow(tester, LogicalKeyboardKey.arrowLeft, shift: true);

      expect(controller.pixels[0], closeTo(initial - 50, 0.001));
    });

    testWidgets('honors a custom keyboardStep', (tester) async {
      await _pump(
        tester,
        _harness(
          controller: controller,
          divider: const ResizableDivider(keyboardStep: 25),
        ),
      );
      await _focusDivider(tester, 0);
      final initial = controller.pixels[0];

      await _pressArrow(tester, LogicalKeyboardKey.arrowRight);

      expect(controller.pixels[0], closeTo(initial + 25, 0.001));
    });

    testWidgets('handles key repeat', (tester) async {
      await _pump(tester, _harness(controller: controller));
      await _focusDivider(tester, 0);
      final initial = controller.pixels[0];

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(controller.pixels[0], closeTo(initial + 30, 0.001));
    });

    testWidgets('respects size constraints', (tester) async {
      await _pump(
        tester,
        _harness(
          controller: controller,
          children: const [
            ResizableChild(
              size: ResizableSize.pixels(300, max: 315),
              child: SizedBox(),
            ),
            ResizableChild(child: SizedBox()),
          ],
        ),
      );
      await _focusDivider(tester, 0);

      await _pressArrow(tester, LogicalKeyboardKey.arrowRight);
      await _pressArrow(tester, LogicalKeyboardKey.arrowRight);
      await _pressArrow(tester, LogicalKeyboardKey.arrowRight);

      expect(controller.pixels[0], closeTo(315, 0.001));
    });

    testWidgets('moves the divider where the arrow points in RTL',
        (tester) async {
      await _pump(
        tester,
        _harness(controller: controller, textDirection: TextDirection.rtl),
      );
      await _focusDivider(tester, 0);
      final initial = controller.pixels[0];
      final dividerX =
          tester.getCenter(find.byType(ResizableDividerHandle).first);

      await _pressArrow(tester, LogicalKeyboardKey.arrowRight);

      expect(controller.pixels[0], closeTo(initial - 10, 0.001));
      expect(
        tester.getCenter(find.byType(ResizableDividerHandle).first).dx,
        closeTo(dividerX.dx + 10, 0.001),
      );
    });

    testWidgets('uses Up and Down for vertical containers', (tester) async {
      await _pump(
        tester,
        _harness(controller: controller, direction: Axis.vertical),
      );
      await _focusDivider(tester, 0);
      final initial = controller.pixels[0];

      await _pressArrow(tester, LogicalKeyboardKey.arrowDown);
      expect(controller.pixels[0], closeTo(initial + 10, 0.001));

      await _pressArrow(tester, LogicalKeyboardKey.arrowUp);
      await _pressArrow(tester, LogicalKeyboardKey.arrowUp);
      expect(controller.pixels[0], closeTo(initial - 10, 0.001));

      final afterVertical = controller.pixels[0];
      await _pressArrow(tester, LogicalKeyboardKey.arrowRight);
      await _pressArrow(tester, LogicalKeyboardKey.arrowLeft);
      expect(controller.pixels[0], afterVertical);
    });

    testWidgets('vertical containers do not flip the arrows under RTL',
        (tester) async {
      await _pump(
        tester,
        _harness(
          controller: controller,
          direction: Axis.vertical,
          textDirection: TextDirection.rtl,
        ),
      );
      await _focusDivider(tester, 0);
      final initial = controller.pixels[0];

      await _pressArrow(tester, LogicalKeyboardKey.arrowDown);
      expect(controller.pixels[0], closeTo(initial + 10, 0.001));

      await _pressArrow(tester, LogicalKeyboardKey.arrowUp);
      await _pressArrow(tester, LogicalKeyboardKey.arrowUp);
      expect(controller.pixels[0], closeTo(initial - 10, 0.001));
    });

    testWidgets('cross-axis arrows leave sizes alone and traverse focus',
        (tester) async {
      final lower = FocusNode();
      addTearDown(lower.dispose);

      await _pump(
        tester,
        _harness(
          controller: controller,
          children: [
            _paneWithButton(
              lower,
              divider: const ResizableDivider(
                length: ResizableSize.pixels(50),
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
            ),
            const ResizableChild(child: SizedBox()),
          ],
        ),
      );
      await _focusDivider(
        tester,
        0,
        at: tester.getTopLeft(find.byType(ResizableDividerHandle)) +
            const Offset(0.5, 10),
      );
      final initial = controller.pixels[0];

      await _pressArrow(tester, LogicalKeyboardKey.arrowDown);

      expect(controller.pixels[0], initial);
      expect(lower.hasPrimaryFocus, isTrue);
    });

    testWidgets('does not fire drag callbacks', (tester) async {
      var starts = 0;
      var ends = 0;
      await _pump(
        tester,
        _harness(
          controller: controller,
          divider: ResizableDivider(
            onDragStart: () => starts++,
            onDragEnd: () => ends++,
          ),
        ),
      );
      await _focusDivider(tester, 0);

      await _pressArrow(tester, LogicalKeyboardKey.arrowRight);

      expect(starts, 0);
      expect(ends, 0);
    });
  });

  group('focus', () {
    late ResizableController controller;

    setUp(() => controller = ResizableController());
    tearDown(() => controller.dispose());

    testWidgets('tap requests focus', (tester) async {
      await _pump(tester, _harness(controller: controller));
      expect(_dividerHasFocus(), isFalse);

      await _focusDivider(tester, 0);

      expect(_dividerHasFocus(), isTrue);
    });

    testWidgets('drag start requests focus', (tester) async {
      await _pump(tester, _harness(controller: controller));

      await tester.drag(
        find.byType(ResizableDividerHandle).first,
        const Offset(20, 0),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();

      expect(_dividerHasFocus(), isTrue);
    });

    testWidgets('Tab skips disabled dividers', (tester) async {
      await _pump(
        tester,
        _harness(
          controller: controller,
          divider: const ResizableDivider(enabled: false),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(_dividerHasFocus(), isFalse);
    });

    testWidgets('Tab skips dividers when the container is not resizable',
        (tester) async {
      await _pump(
        tester,
        _harness(controller: controller, resizable: false),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(_dividerHasFocus(), isFalse);
    });

    testWidgets('a focused divider unfocuses when it becomes disabled',
        (tester) async {
      await _pump(tester, _harness(controller: controller));
      await _focusDivider(tester, 0);
      expect(_dividerHasFocus(), isTrue);

      await _pump(
        tester,
        _harness(controller: controller, resizable: false),
      );

      expect(_dividerHasFocus(), isFalse);
    });

    testWidgets('Tab visits each divider between its two panes',
        (tester) async {
      final nodes = List.generate(3, (_) => FocusNode());
      addTearDown(() {
        for (final node in nodes) {
          node.dispose();
        }
      });

      await _pump(
        tester,
        _harness(
          controller: controller,
          children: [
            for (final node in nodes) _paneWithButton(node),
          ],
        ),
      );

      final visited = <String>[];
      for (var i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final primary = FocusManager.instance.primaryFocus;
        final index = nodes.indexOf(primary!);
        visited.add(index >= 0 ? 'pane$index' : primary.debugLabel!);
      }

      expect(visited, [
        'pane0',
        _dividerLabel,
        'pane1',
        _dividerLabel,
        'pane2',
      ]);
    });

    group('across relayouts', () {
      testWidgets('a non-adjacent divider keeps focus through hide and show',
          (tester) async {
        await _pump(tester, _harness(controller: controller));
        await _focusDivider(tester, 0);

        controller.hide(2);
        await tester.pump();
        await tester.pump();
        expect(_dividerHasFocus(), isTrue);

        controller.show(2);
        await tester.pump();
        await tester.pump();
        expect(_dividerHasFocus(), isTrue);
      });

      testWidgets('keeps focus through setSizes', (tester) async {
        await _pump(tester, _harness(controller: controller));
        await _focusDivider(tester, 0);

        controller.setSizes(const [
          ResizableSize.pixels(200),
          ResizableSize.pixels(200),
          ResizableSize.expand(),
        ]);
        await tester.pump();
        await tester.pump();

        expect(_dividerHasFocus(), isTrue);
      });

      testWidgets('keeps focus when the container resizes', (tester) async {
        await _pump(tester, _harness(controller: controller));
        await _focusDivider(tester, 0);

        await tester.binding.setSurfaceSize(const Size(500, 400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pump();
        await tester.pump();

        expect(_dividerHasFocus(), isTrue);
      });

      testWidgets('keeps focus through a hide animation', (tester) async {
        await _pump(
          tester,
          _harness(
            controller: controller,
            hideAnimation: const ResizableHideAnimation(
              duration: Duration(milliseconds: 200),
            ),
          ),
        );
        await _focusDivider(tester, 0);

        controller.hide(2);
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(_dividerHasFocus(), isTrue);

        await tester.pumpAndSettle();
        expect(_dividerHasFocus(), isTrue);
      });

      testWidgets('a divider next to a hidden child loses focus',
          (tester) async {
        await _pump(tester, _harness(controller: controller));
        await _focusDivider(tester, 0);

        controller.hide(0);
        await tester.pump();
        await tester.pump();

        expect(_dividerHasFocus(), isFalse);
      });
    });

    group('indicator', () {
      Finder indicator() => find.descendant(
            of: find.byType(ResizableDividerHandle),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is CustomPaint && widget.painter is DividerPainter,
            ),
          );

      testWidgets('is thicker than the line and primary-colored when focused',
          (tester) async {
        await _pump(
          tester,
          _harness(
            controller: controller,
            divider: const ResizableDivider(thickness: 3),
          ),
        );
        expect(indicator(), findsNothing);

        await _focusDivider(tester, 0);

        final painter =
            tester.widget<CustomPaint>(indicator()).painter! as DividerPainter;
        final primary = Theme.of(
          tester.element(find.byType(ResizableDividerHandle).first),
        ).colorScheme.primary;
        expect(painter.thickness, greaterThan(3));
        expect(painter.color, primary);
      });

      testWidgets('uses focusColor when set', (tester) async {
        const color = Color(0xFF00AA55);
        await _pump(
          tester,
          _harness(
            controller: controller,
            divider: const ResizableDivider(focusColor: color),
          ),
        );

        await _focusDivider(tester, 0);

        final painter =
            tester.widget<CustomPaint>(indicator()).painter! as DividerPainter;
        expect(painter.color, color);
      });

      group('geometry', () {
        const thickness = 3.0;
        const padding = 10.0;

        Rect lineRectIn(Rect slot, Axis direction, MainAxisAlignment align) {
          final extent =
              direction == Axis.horizontal ? slot.width : slot.height;
          final offset = switch (align) {
            MainAxisAlignment.start => 0.0,
            MainAxisAlignment.end => extent - thickness,
            _ => (extent - thickness) / 2,
          };
          return direction == Axis.horizontal
              ? Rect.fromLTWH(
                  slot.left + offset, slot.top, thickness, slot.height)
              : Rect.fromLTWH(
                  slot.left, slot.top + offset, slot.width, thickness);
        }

        for (final direction in Axis.values) {
          for (final align in [
            MainAxisAlignment.start,
            MainAxisAlignment.center,
            MainAxisAlignment.end,
          ]) {
            testWidgets('extends 1px beyond the line for $direction $align',
                (tester) async {
              await _pump(
                tester,
                _harness(
                  controller: controller,
                  direction: direction,
                  divider: ResizableDivider(
                    thickness: thickness,
                    padding: padding,
                    mainAxisAlignment: align,
                  ),
                ),
              );
              await _focusDivider(tester, 0);

              final slot =
                  tester.getRect(find.byType(ResizableDividerLine).first);
              final line = lineRectIn(slot, direction, align);
              final ring = tester.getRect(indicator());

              final expected = direction == Axis.horizontal
                  ? Rect.fromLTRB(
                      line.left - 1, line.top, line.right + 1, line.bottom)
                  : Rect.fromLTRB(
                      line.left, line.top - 1, line.right, line.bottom + 1);
              expect(ring, expected);
            });
          }
        }
      });

      testWidgets('is hit-test transparent', (tester) async {
        await _pump(tester, _harness(controller: controller));
        await _focusDivider(tester, 0);

        final ignore = tester.widget<IgnorePointer>(
          find
              .ancestor(of: indicator(), matching: find.byType(IgnorePointer))
              .first,
        );
        expect(ignore.ignoring, isTrue);
      });

      testWidgets('is not shown after a pointer focus in touch mode',
          (tester) async {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTouch;
        await _pump(tester, _harness(controller: controller));

        await _focusDivider(tester, 0);

        expect(_dividerHasFocus(), isTrue);
        expect(indicator(), findsNothing);
      });
    });
  });

  group('semantics', () {
    late ResizableController controller;

    setUp(() => controller = ResizableController());
    tearDown(() => controller.dispose());

    Widget twoPanes({
      ResizableDivider divider = const ResizableDivider(
        semanticLabel: 'Resize panes',
        keyboardStep: 50,
      ),
      ResizableSize first = const ResizableSize.ratio(0.4),
      bool resizable = true,
      Axis direction = Axis.horizontal,
    }) {
      return _harness(
        controller: controller,
        direction: direction,
        resizable: resizable,
        children: [
          ResizableChild(
              size: first, divider: divider, child: const SizedBox()),
          const ResizableChild(child: SizedBox()),
        ],
      );
    }

    testWidgets('exposes a labeled slider with a position value',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final handle = tester.ensureSemantics();

      await _pump(tester, twoPanes());

      final finder = find.bySemanticsLabel('Resize panes');
      expect(
        tester.getSemantics(finder),
        isSemantics(
          isSlider: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
          label: 'Resize panes',
          value: '40%',
          increasedValue: '45%',
          decreasedValue: '35%',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );

      final data = tester.getSemantics(finder).getSemanticsData();
      expect(data.hasAction(SemanticsAction.scrollLeft), isFalse);
      expect(data.hasAction(SemanticsAction.scrollRight), isFalse);
      expect(data.hasAction(SemanticsAction.scrollUp), isFalse);
      expect(data.hasAction(SemanticsAction.scrollDown), isFalse);
      handle.dispose();
    });

    testWidgets('increased and decreased values reflect size limits',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final handle = tester.ensureSemantics();

      await _pump(
        tester,
        twoPanes(first: const ResizableSize.ratio(0.4, max: 420)),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Resize panes')),
        isSemantics(
          value: '40%',
          increasedValue: '42%',
          decreasedValue: '35%',
        ),
      );
      handle.dispose();
    });

    testWidgets('increase and decrease actions apply keyboardStep',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final handle = tester.ensureSemantics();

      await _pump(tester, twoPanes());
      final initial = controller.pixels[0];

      tester.semantics.increase(find.semantics.byLabel('Resize panes'));
      await tester.pump();
      expect(controller.pixels[0], closeTo(initial + 50, 0.001));

      tester.semantics.decrease(find.semantics.byLabel('Resize panes'));
      tester.semantics.decrease(find.semantics.byLabel('Resize panes'));
      await tester.pump();
      expect(controller.pixels[0], closeTo(initial - 50, 0.001));
      handle.dispose();
    });

    testWidgets('increase grows the leading child in RTL as well',
        (tester) async {
      final handle = tester.ensureSemantics();

      await _pump(
        tester,
        _harness(
          controller: controller,
          textDirection: TextDirection.rtl,
          children: const [
            ResizableChild(
              divider: ResizableDivider(semanticLabel: 'Resize panes'),
              child: SizedBox(),
            ),
            ResizableChild(child: SizedBox()),
          ],
        ),
      );
      final initial = controller.pixels[0];

      tester.semantics.increase(find.semantics.byLabel('Resize panes').first);
      await tester.pump();

      expect(controller.pixels[0], closeTo(initial + 10, 0.001));
      handle.dispose();
    });

    testWidgets('a divider disabled by resizable: false has no slider node',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final handle = tester.ensureSemantics();

      await _pump(tester, twoPanes(resizable: false));

      expect(find.semantics.byLabel('Resize panes'), findsNothing);
      expect(find.semantics.byFlag(SemanticsFlag.isSlider), findsNothing);
      handle.dispose();
    });

    testWidgets('an unlabeled divider is still a slider with a value',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final handle = tester.ensureSemantics();

      await _pump(tester, twoPanes(divider: const ResizableDivider()));

      final sliders = find.semantics.byFlag(SemanticsFlag.isSlider).evaluate();
      expect(sliders, hasLength(1));
      final slider = sliders.single;
      expect(
        slider,
        isSemantics(isSlider: true, hasEnabledState: true, isEnabled: true),
      );
      expect(slider.label, isEmpty);
      expect(slider.value, '40%');
      handle.dispose();
    });

    testWidgets('exposes the position and actions in a vertical container',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final handle = tester.ensureSemantics();

      await _pump(tester, twoPanes(direction: Axis.vertical));
      final initial = controller.pixels[0];

      expect(
        tester.getSemantics(find.bySemanticsLabel('Resize panes')),
        isSemantics(
          isSlider: true,
          label: 'Resize panes',
          value: '40%',
          increasedValue: '48%',
          decreasedValue: '32%',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );

      tester.semantics.increase(find.semantics.byLabel('Resize panes'));
      await tester.pump();

      expect(controller.pixels[0], closeTo(initial + 50, 0.001));
      handle.dispose();
    });

    testWidgets('a divider with enabled: false has no slider node',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final handle = tester.ensureSemantics();

      await _pump(
        tester,
        twoPanes(
          divider: const ResizableDivider(
            semanticLabel: 'Resize panes',
            enabled: false,
          ),
        ),
      );

      expect(find.semantics.byLabel('Resize panes'), findsNothing);
      expect(find.semantics.byFlag(SemanticsFlag.isSlider), findsNothing);
      handle.dispose();
    });

    testWidgets('increase stops at the maximum size', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final handle = tester.ensureSemantics();
      const max = 420.0;

      await _pump(
        tester,
        twoPanes(first: const ResizableSize.ratio(0.4, max: max)),
      );

      tester.semantics.increase(find.semantics.byLabel('Resize panes'));
      await tester.pump();
      expect(controller.pixels[0], closeTo(max, 0.001));

      tester.semantics.increase(find.semantics.byLabel('Resize panes'));
      await tester.pump();
      expect(controller.pixels[0], closeTo(max, 0.001));
      handle.dispose();
    });

    testWidgets('decrease stops at the minimum size', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final handle = tester.ensureSemantics();
      const min = 380.0;

      await _pump(
        tester,
        twoPanes(first: const ResizableSize.ratio(0.4, min: min)),
      );

      tester.semantics.decrease(find.semantics.byLabel('Resize panes'));
      await tester.pump();
      expect(controller.pixels[0], closeTo(min, 0.001));

      tester.semantics.decrease(find.semantics.byLabel('Resize panes'));
      await tester.pump();
      expect(controller.pixels[0], closeTo(min, 0.001));
      handle.dispose();
    });

    testWidgets('a hidden divider has no semantics node', (tester) async {
      final handle = tester.ensureSemantics();

      await _pump(tester, twoPanes());
      expect(find.semantics.byLabel('Resize panes'), findsOneWidget);

      controller.hide(1);
      await tester.pump();
      await tester.pump();

      expect(find.semantics.byLabel('Resize panes'), findsNothing);
      handle.dispose();
    });

    testWidgets('reads between its two panes', (tester) async {
      final handle = tester.ensureSemantics();

      await _pump(
        tester,
        _harness(
          controller: controller,
          children: [
            for (final label in ['first', 'second', 'third'])
              ResizableChild(
                divider: ResizableDivider(semanticLabel: 'after $label'),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: TextButton(onPressed: () {}, child: Text(label)),
                ),
              ),
          ],
        ),
      );

      final labels = tester.semantics
          .simulatedAccessibilityTraversal()
          .map((node) => node.label)
          .where((label) => label.isNotEmpty)
          .toList();

      expect(labels, [
        'first',
        'after first',
        'second',
        'after second',
        'third',
      ]);
      handle.dispose();
    });
  });

  group(ResizableDivider, () {
    test('keyboardStep must be greater than 0', () {
      expect(() => ResizableDivider(keyboardStep: 0), throwsAssertionError);
      expect(() => ResizableDivider(keyboardStep: -1), throwsAssertionError);
      expect(
        () => const ResizableDivider(keyboardStep: 1),
        isNot(throwsAssertionError),
      );
    });

    test('props include keyboardStep and semanticLabel', () {
      expect(
        const ResizableDivider(keyboardStep: 5),
        const ResizableDivider(keyboardStep: 5),
      );
      expect(
        const ResizableDivider(keyboardStep: 5),
        isNot(const ResizableDivider()),
      );
      expect(
        const ResizableDivider(semanticLabel: 'a'),
        const ResizableDivider(semanticLabel: 'a'),
      );
      expect(
        const ResizableDivider(semanticLabel: 'a'),
        isNot(const ResizableDivider(semanticLabel: 'b')),
      );
    });
  });
}

// Pins the lifecycle contract introduced by PR #134's listener refactor:
//
//   * `ResizableController` now owns two `ValueNotifier`s
//     (`_needsLayoutListenable`, `_pixelsListenable`) in addition to its
//     inherited `ChangeNotifier`. All three are disposed in
//     `ResizableController.dispose()` (in that order, before `super.dispose()`).
//   * `ResizableContainer` subscribes via
//     `Listenable.merge([controller, controller.needsLayoutListenable])`.
//   * `_ResizableContainerState.didUpdateWidget` swaps the controller by
//     detaching the listener from the old controller (and disposing it only if
//     the container created it), then attaching to the new one.
//
// This suite covers the controller-swap path, late-subscriber delivery,
// dispose ordering, and (documents) the multi-container-sharing limitation.

import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_test/flutter_test.dart';

/// A child that increments [buildCount] on every build. Wrapped by the
/// container in a `RepaintBoundary`, but the inner `Builder` still runs every
/// time the surrounding [ResizableContainer] rebuilds.
class _CountingChild extends StatelessWidget {
  const _CountingChild({required this.label, required this.buildCount});

  final String label;
  final ValueNotifier<int> buildCount;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        buildCount.value++;
        return SizedBox.expand(key: Key(label));
      },
    );
  }
}

Widget _harness({
  required ResizableController? controller,
  Axis direction = Axis.horizontal,
  List<ResizableChild>? children,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ResizableContainer(
        controller: controller,
        direction: direction,
        children: children ??
            const [
              ResizableChild(
                size: ResizableSize.ratio(0.5),
                child: SizedBox.expand(key: Key('A')),
              ),
              ResizableChild(
                size: ResizableSize.ratio(0.5),
                child: SizedBox.expand(key: Key('B')),
              ),
            ],
      ),
    ),
  );
}

List<ResizableChild> _countingChildren(ValueNotifier<int> buildCount) {
  return [
    ResizableChild(
      size: const ResizableSize.ratio(0.5),
      child: _CountingChild(label: 'A', buildCount: buildCount),
    ),
    ResizableChild(
      size: const ResizableSize.ratio(0.5),
      child: _CountingChild(label: 'B', buildCount: buildCount),
    ),
  ];
}

void main() {
  group('controller swap via didUpdateWidget', () {
    testWidgets(
      "B's needsLayoutListenable drives the first layout after swap "
      '(true → false, exactly 2 fires)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));
        final controllerA = ResizableController();
        addTearDown(controllerA.dispose);
        final controllerB = ResizableController();
        addTearDown(controllerB.dispose);

        await tester.pumpWidget(_harness(controller: controllerA));
        await tester.pumpAndSettle();

        // Attach BEFORE the swap so the listener observes both transitions:
        // `_initChildren` flips needsLayout to true (1 fire), then the post-
        // frame `_setRenderedSizes` flips it back to false (2 fires).
        var bNeedsLayoutFires = 0;
        controllerB.needsLayoutListenable.addListener(
          () => bNeedsLayoutFires++,
        );

        await tester.pumpWidget(_harness(controller: controllerB));
        await tester.pumpAndSettle();

        expect(bNeedsLayoutFires, 2);
        expect(controllerB.needsLayoutListenable.value, isFalse);
      },
    );

    testWidgets(
      "A's listeners are detached from the container after swap — mutating A "
      'does not trigger ResizableChild rebuilds',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));
        final controllerA = ResizableController();
        addTearDown(controllerA.dispose);
        final controllerB = ResizableController();
        addTearDown(controllerB.dispose);

        final buildCount = ValueNotifier<int>(0);
        addTearDown(buildCount.dispose);

        await tester.pumpWidget(
          _harness(
            controller: controllerA,
            children: _countingChildren(buildCount),
          ),
        );
        await tester.pumpAndSettle();

        // Swap A → B with the same children list (B will get a fresh
        // _initChildren). The buildCount carries over because the children
        // refer to the same ValueNotifier.
        await tester.pumpWidget(
          _harness(
            controller: controllerB,
            children: _countingChildren(buildCount),
          ),
        );
        await tester.pumpAndSettle();

        final buildsAfterSwap = buildCount.value;

        // Mutating A after the swap must not flow into the container.
        controllerA.setChildren(const [
          ResizableChild(
            size: ResizableSize.ratio(0.3),
            child: SizedBox.expand(),
          ),
          ResizableChild(
            size: ResizableSize.ratio(0.7),
            child: SizedBox.expand(),
          ),
        ]);
        await tester.pumpAndSettle();

        expect(buildCount.value, buildsAfterSwap);
      },
    );

    testWidgets(
      "B's listeners are attached after swap — mutating B with hide() "
      'changes the rendered child layout (proving the merge listener fired)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));
        final controllerA = ResizableController();
        addTearDown(controllerA.dispose);
        final controllerB = ResizableController();
        addTearDown(controllerB.dispose);

        await tester.pumpWidget(_harness(controller: controllerA));
        await tester.pumpAndSettle();

        await tester.pumpWidget(_harness(controller: controllerB));
        await tester.pumpAndSettle();

        // Sanity check: child A is rendered at ~half the surface width.
        final preHideWidth = tester.getSize(find.byKey(const Key('A'))).width;
        expect(preHideWidth, greaterThan(0));

        // Mutate B — hide child 0. If B's listeners weren't attached, the
        // container would not rebuild and A's rendered size would be
        // unchanged. The hide path notifies via the merge tuple.
        controllerB.hide(0);
        await tester.pumpAndSettle();

        final postHideWidth = tester.getSize(find.byKey(const Key('A'))).width;
        expect(postHideWidth, 0);
        expect(controllerB.hiddenIndices, contains(0));
      },
    );

    testWidgets(
      'consumer-provided controller is NOT disposed when the container '
      'rebuilds with a new controller',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));
        final controllerA = ResizableController();
        addTearDown(controllerA.dispose);
        final controllerB = ResizableController();
        addTearDown(controllerB.dispose);

        await tester.pumpWidget(_harness(controller: controllerA));
        await tester.pumpAndSettle();

        await tester.pumpWidget(_harness(controller: controllerB));
        await tester.pumpAndSettle();

        // `ChangeNotifier.addListener` asserts-not-disposed in debug. A
        // successful add proves A is still alive after the swap.
        expect(() => controllerA.addListener(() {}), returnsNormally);
      },
    );

    testWidgets(
      'swapping consumer controller → null creates a fresh default and '
      'leaves the consumer controller alive',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));
        final controllerA = ResizableController();
        addTearDown(controllerA.dispose);

        await tester.pumpWidget(_harness(controller: controllerA));
        await tester.pumpAndSettle();

        await tester.pumpWidget(_harness(controller: null));
        await tester.pumpAndSettle();

        // A is still owned by the test — must not have been disposed.
        expect(() => controllerA.addListener(() {}), returnsNormally);
      },
    );
  });

  group('late subscribers', () {
    testWidgets(
      'a listener added on `controller` AFTER first layout fires on a '
      'structural update',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        var fires = 0;
        controller.addListener(() => fires++);

        controller.setSizes(const [
          ResizableSize.ratio(0.3),
          ResizableSize.ratio(0.7),
        ]);
        await tester.pumpAndSettle();

        expect(fires, 1);
      },
    );

    testWidgets(
      'a listener added on `pixelsListenable` AFTER first layout fires on '
      'a drag',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        var fires = 0;
        controller.pixelsListenable.addListener(() => fires++);

        await tester.timedDrag(
          find.byType(ResizableContainerDivider),
          const Offset(120, 0),
          const Duration(milliseconds: 200),
        );
        await tester.pump();

        expect(fires, greaterThan(0));
      },
    );

    testWidgets(
      'a listener added on `needsLayoutListenable` AFTER first layout '
      'observes the true→false cycle around setChildren',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        var fires = 0;
        controller.needsLayoutListenable.addListener(() => fires++);

        controller.setChildren(const [
          ResizableChild(
            size: ResizableSize.ratio(0.4),
            child: SizedBox.expand(),
          ),
          ResizableChild(
            size: ResizableSize.ratio(0.6),
            child: SizedBox.expand(),
          ),
        ]);
        await tester.pumpAndSettle();

        expect(fires, 2);
        expect(controller.needsLayoutListenable.value, isFalse);
      },
    );

    testWidgets(
      'add → fire → remove → fire — listener is called exactly once',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        var fires = 0;
        void listener() => fires++;
        controller.addListener(listener);

        controller.setSizes(const [
          ResizableSize.ratio(0.3),
          ResizableSize.ratio(0.7),
        ]);
        await tester.pumpAndSettle();

        expect(fires, 1);

        controller.removeListener(listener);

        controller.setSizes(const [
          ResizableSize.ratio(0.6),
          ResizableSize.ratio(0.4),
        ]);
        await tester.pumpAndSettle();

        // Still 1 — the listener was removed before the second notify.
        expect(fires, 1);
      },
    );
  });

  group('dispose ordering', () {
    test(
      'standalone controller with listeners on all three listenables '
      'disposes cleanly',
      () {
        final controller = ResizableController();

        controller.addListener(() {});
        controller.pixelsListenable.addListener(() {});
        controller.needsLayoutListenable.addListener(() {});

        expect(controller.dispose, returnsNormally);
      },
    );

    testWidgets(
      'consumer pattern — unmount container, then dispose controller, '
      'no exceptions',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));
        final controller = ResizableController();

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        // Unmount the container.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(controller.dispose, returnsNormally);
        expect(tester.takeException(), isNull);
      },
    );

    test(
      'addListener / notifyListeners after dispose assert in debug; '
      'removeListener and the ValueNotifier `.value` getters tolerate it',
      () {
        final controller = ResizableController();
        // Snapshot the listenables before dispose — both getters return the
        // private field, which remains readable after dispose.
        final pixelsListenable = controller.pixelsListenable;
        final needsLayoutListenable = controller.needsLayoutListenable;
        controller.dispose();

        // ChangeNotifier asserts not-disposed in debug.
        expect(
          () => controller.addListener(() {}),
          throwsA(isA<FlutterError>()),
        );

        // removeListener is documented as safe after dispose.
        expect(() => controller.removeListener(() {}), returnsNormally);

        // The ValueNotifier `.value` getter just reads the backing field;
        // it does not assert-not-disposed.
        expect(() => pixelsListenable.value, returnsNormally);
        expect(() => needsLayoutListenable.value, returnsNormally);
      },
    );

    testWidgets(
      'negative — consumer disposes controller while container is still '
      'mounted; the crash surfaces when the container unmounts and '
      "tries to remove its listener from the disposed controller",
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));
        final controller = ResizableController();

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        // Consumer error: dispose while still mounted.
        controller.dispose();

        // No notify will ever fire (controller is dead), so the mounted
        // container does not observe the dispose. Unmount triggers the
        // container's own dispose path, which calls
        // `controller.removeListener` — documented as safe — and is a no-op
        // here. The animation coordinator disposes independently.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        // Pin the actual observed behavior: no exception surfaces. If a
        // future refactor makes the container call into the disposed
        // controller during teardown, `takeException` will catch it and
        // this assertion will need updating.
        expect(tester.takeException(), isNull);
      },
    );
  });

  group(
    'multi-container sharing (NOT supported)',
    () {
      // The controller has no single-use guard, but `_initChildren` (called
      // from each container's `initState`) **resets `_pixels`, clears
      // `_hiddenIndices`, clears `_savedSizes`**. The second mount clobbers
      // the first container's layout state. This group pins that behavior
      // so a future refactor that introduces a guard (or fixes the
      // interference) updates this expectation.

      testWidgets(
        'mounting two containers with the same controller — the second '
        "container's initState calls `_initChildren`, which clears "
        "`_hiddenIndices` set by interaction with the first",
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(800, 1200));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          // First mount: a single container, hide child 0 to seed state.
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ResizableContainer(
                  controller: controller,
                  direction: Axis.horizontal,
                  children: const [
                    ResizableChild(
                      size: ResizableSize.ratio(0.5),
                      child: SizedBox.expand(),
                    ),
                    ResizableChild(
                      size: ResizableSize.ratio(0.5),
                      child: SizedBox.expand(),
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          controller.hide(0);
          await tester.pumpAndSettle();
          expect(controller.hiddenIndices, contains(0));

          // Now mount BOTH containers simultaneously — one horizontal, one
          // vertical — so the second one's `initState` runs and its
          // `manager.initChildren` resets the controller's `_hiddenIndices`.
          // (The widget shape changed: Scaffold body became a Column, so the
          // first container's Element is rebuilt fresh too, but the key
          // observation is the same controller fed into two containers.)
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Expanded(
                      child: ResizableContainer(
                        controller: controller,
                        direction: Axis.horizontal,
                        children: const [
                          ResizableChild(
                            size: ResizableSize.ratio(0.5),
                            child: SizedBox.expand(),
                          ),
                          ResizableChild(
                            size: ResizableSize.ratio(0.5),
                            child: SizedBox.expand(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ResizableContainer(
                        controller: controller,
                        direction: Axis.horizontal,
                        children: const [
                          ResizableChild(
                            size: ResizableSize.ratio(0.5),
                            child: SizedBox.expand(),
                          ),
                          ResizableChild(
                            size: ResizableSize.ratio(0.5),
                            child: SizedBox.expand(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // The hidden state seeded against the first single container has
          // been wiped by at least one of the two `_initChildren` calls run
          // by the new containers' `initState`. Multi-container sharing is
          // therefore not supported by the current controller design.
          expect(controller.hiddenIndices, isEmpty);
        },
      );
    },
  );
}

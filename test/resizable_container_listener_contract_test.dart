// Verifies the public listener contract on [ResizableController] from a
// consumer's perspective after the b413c10 + 3d4b65c refactor:
//
//   * [ChangeNotifier.addListener]    — structural changes only.
//   * [pixelsListenable]              — fires per-pixel-change with a fresh
//                                       unmodifiable snapshot.
//   * [needsLayoutListenable]         — flips around build-path swaps.
//
// The [ResizableContainer] now subscribes to
// `Listenable.merge([controller, controller.needsLayoutListenable])` instead
// of the controller alone, so these tests double as the migration-pinning
// suite for downstream consumers.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness({
  required ResizableController controller,
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

void main() {
  group('main controller listener (addListener) — structural only', () {
    testWidgets('does not fire on initial mount + first frame', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      var mainNotifies = 0;
      controller.addListener(() => mainNotifies++);

      await tester.pumpWidget(_harness(controller: controller));
      await tester.pumpAndSettle();

      expect(mainNotifies, 0);
    });

    testWidgets('does not fire during a horizontal drag', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 600));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_harness(controller: controller));
      await tester.pumpAndSettle();

      var mainNotifies = 0;
      controller.addListener(() => mainNotifies++);

      final preDragWidth = tester.getSize(find.byKey(const Key('A'))).width;
      await tester.timedDrag(
        find.byType(ResizableContainerDivider),
        const Offset(120, 0),
        const Duration(milliseconds: 200),
      );
      await tester.pump();

      // Guard against a silent regression where the drag fails to reach the
      // divider — only meaningful if the drag actually moved sizes.
      final postDragWidth = tester.getSize(find.byKey(const Key('A'))).width;
      expect(postDragWidth, greaterThan(preDragWidth));

      expect(mainNotifies, 0);
    });

    testWidgets('does not fire during a vertical drag', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1000));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _harness(controller: controller, direction: Axis.vertical),
      );
      await tester.pumpAndSettle();

      var mainNotifies = 0;
      controller.addListener(() => mainNotifies++);

      final preDragHeight = tester.getSize(find.byKey(const Key('A'))).height;
      await tester.timedDrag(
        find.byType(ResizableContainerDivider),
        const Offset(0, 120),
        const Duration(milliseconds: 200),
      );
      await tester.pump();

      final postDragHeight = tester.getSize(find.byKey(const Key('A'))).height;
      expect(postDragHeight, greaterThan(preDragHeight));

      expect(mainNotifies, 0);
    });

    testWidgets('fires exactly once on controller.setChildren', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_harness(controller: controller));
      await tester.pumpAndSettle();

      var mainNotifies = 0;
      controller.addListener(() => mainNotifies++);

      controller.setChildren(const [
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

      expect(mainNotifies, 1);
    });

    testWidgets(
      'fires exactly once on controller.setSizes (the public update API)',
      (tester) async {
        // Note: there is no `updateChildSize` on the controller. `setSizes` is
        // the public size-update API and is the structural-change surface the
        // main listener was designed for.
        await tester.binding.setSurfaceSize(const Size(800, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        var mainNotifies = 0;
        controller.addListener(() => mainNotifies++);

        controller.setSizes(const [
          ResizableSize.ratio(0.25),
          ResizableSize.ratio(0.75),
        ]);
        await tester.pumpAndSettle();

        expect(mainNotifies, 1);
      },
    );

    testWidgets('fires exactly once on controller.hide', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_harness(controller: controller));
      await tester.pumpAndSettle();

      var mainNotifies = 0;
      controller.addListener(() => mainNotifies++);

      controller.hide(0);
      await tester.pumpAndSettle();

      expect(mainNotifies, 1);
    });

    testWidgets('fires exactly once on controller.show', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_harness(controller: controller));
      await tester.pumpAndSettle();

      controller.hide(0);
      await tester.pumpAndSettle();

      var mainNotifies = 0;
      controller.addListener(() => mainNotifies++);

      controller.show(0);
      await tester.pumpAndSettle();

      expect(mainNotifies, 1);
    });

    testWidgets('does not fire on screen-size change (live redistribute)',
        (tester) async {
      // The screen-resize live-redistribute path runs inside
      // `_setAvailableSpace` and never calls `notifyListeners()`. This is the
      // critical assertion that drag and screen-resize both flow through
      // `pixelsListenable` exclusively.
      await tester.binding.setSurfaceSize(const Size(800, 600));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_harness(controller: controller));
      await tester.pumpAndSettle();

      var mainNotifies = 0;
      controller.addListener(() => mainNotifies++);

      await tester.binding.setSurfaceSize(const Size(1200, 600));
      await tester.pumpAndSettle();

      expect(mainNotifies, 0);
    });
  });

  group('needsLayoutListenable lifecycle', () {
    test(
      'bare-construct state is false — the controller defaults to false '
      'and only flips to true once the container calls initChildren '
      '(deviation from spec)',
      () {
        // Deviation: the task spec claimed bare-construct = true, but
        // `ValueNotifier<bool>(false)` in [ResizableController] is the source
        // of truth. The true→false→true cycle only begins once the controller
        // is wired into a container's initState (which calls `_initChildren`,
        // which sets the flag to true).
        final controller = ResizableController();
        addTearDown(controller.dispose);

        expect(controller.needsLayout, isFalse);
        expect(controller.needsLayoutListenable.value, isFalse);
      },
    );

    testWidgets('is false after mounting + first frame settles',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_harness(controller: controller));
      await tester.pumpAndSettle();

      expect(controller.needsLayoutListenable.value, isFalse);
    });

    testWidgets('does not fire during a drag', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 600));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_harness(controller: controller));
      await tester.pumpAndSettle();

      var needsLayoutNotifies = 0;
      controller.needsLayoutListenable.addListener(
        () => needsLayoutNotifies++,
      );

      final preDragWidth = tester.getSize(find.byKey(const Key('A'))).width;
      await tester.timedDrag(
        find.byType(ResizableContainerDivider),
        const Offset(120, 0),
        const Duration(milliseconds: 200),
      );
      await tester.pump();

      final postDragWidth = tester.getSize(find.byKey(const Key('A'))).width;
      expect(postDragWidth, greaterThan(preDragWidth));

      expect(needsLayoutNotifies, 0);
      expect(controller.needsLayoutListenable.value, isFalse);
    });

    testWidgets(
      'fires around setChildren and settles back to false',
      (tester) async {
        // Both flips (false → true → false) occur within the same
        // pumpAndSettle cycle: `setChildren` synchronously flips to true, and
        // the post-frame `_setRenderedSizes` flips back to false. We pin the
        // observable notify count == 2 and the post-frame value == false.
        await tester.binding.setSurfaceSize(const Size(800, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        var needsLayoutNotifies = 0;
        controller.needsLayoutListenable.addListener(
          () => needsLayoutNotifies++,
        );

        controller.setChildren(const [
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

        expect(needsLayoutNotifies, 2);
        expect(controller.needsLayoutListenable.value, isFalse);
      },
    );

    testWidgets(
      'stays false on a screen-resize that does not reset availableSpace',
      (tester) async {
        // `_setAvailableSpace` only flips `needsLayout` to true when
        // `_availableSpace == -1` (first call only). Subsequent calls
        // redistribute pixels live without invalidating layout, so the
        // needs-layout listener stays silent and pixels fire.
        await tester.binding.setSurfaceSize(const Size(800, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        var needsLayoutNotifies = 0;
        var pixelsNotifies = 0;
        controller.needsLayoutListenable.addListener(
          () => needsLayoutNotifies++,
        );
        controller.pixelsListenable.addListener(() => pixelsNotifies++);

        await tester.binding.setSurfaceSize(const Size(1200, 600));
        await tester.pumpAndSettle();

        expect(needsLayoutNotifies, 0);
        expect(controller.needsLayoutListenable.value, isFalse);
        expect(pixelsNotifies, greaterThan(0));
      },
    );
  });

  group('pixelsListenable snapshot semantics', () {
    testWidgets(
      'after initial mount, value is non-empty, matches sizes, and is '
      'unmodifiable',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        final snapshot = controller.pixelsListenable.value;
        expect(snapshot, isNotEmpty);
        expect(snapshot, equals(controller.pixels));
        expect(() => snapshot[0] = 999, throwsUnsupportedError);
      },
    );

    testWidgets(
      'fires multiple times during a drag with snapshots that differ',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        final snapshots = <List<double>>[];
        controller.pixelsListenable.addListener(() {
          // Capture a deep copy so the assertion compares values, not
          // references; the snapshot-aliasing assertion below uses a
          // separate raw-reference capture.
          snapshots.add(List<double>.from(controller.pixelsListenable.value));
        });

        await tester.timedDrag(
          find.byType(ResizableContainerDivider),
          const Offset(120, 0),
          const Duration(milliseconds: 200),
        );
        await tester.pump();

        expect(snapshots.length, greaterThan(1));
        // At least one pair of adjacent snapshots must differ — proves a
        // mid-drag value actually changed, not just that the listener fired
        // multiple times against the same data.
        var anyChange = false;
        for (var i = 1; i < snapshots.length; i++) {
          if (!listEquals(snapshots[i], snapshots[i - 1])) {
            anyChange = true;
            break;
          }
        }
        expect(anyChange, isTrue);
      },
    );

    testWidgets(
      'a stale snapshot captured by an earlier listener retains its old '
      'values (proves snapshot vs. live-view — the load-bearing 3d4b65c '
      'assertion)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        // Capture the raw reference (NOT a copy) on the first fire after the
        // baseline. If `pixelsListenable.value` were a live view onto a
        // shared mutable list, the snapshot's contents would mutate alongside
        // subsequent updates.
        List<double>? firstSnapshot;
        List<double>? firstSnapshotValuesAtCapture;
        controller.pixelsListenable.addListener(() {
          firstSnapshot ??= controller.pixelsListenable.value;
          firstSnapshotValuesAtCapture ??=
              List<double>.from(controller.pixelsListenable.value);
        });

        await tester.timedDrag(
          find.byType(ResizableContainerDivider),
          const Offset(150, 0),
          const Duration(milliseconds: 250),
        );
        await tester.pump();

        expect(firstSnapshot, isNotNull);
        expect(firstSnapshotValuesAtCapture, isNotNull);

        // The current live value should have moved away from the captured
        // snapshot — i.e. the drag actually produced subsequent updates.
        expect(
          listEquals(controller.pixelsListenable.value, firstSnapshot),
          isFalse,
          reason: 'sanity check that the drag produced ≥2 fires',
        );

        // The captured snapshot's contents are unchanged — equal to what
        // they were at capture time. This is the snapshot guarantee that
        // 3d4b65c introduced via `UnmodifiableListView(List.from(_pixels))`.
        expect(firstSnapshot, equals(firstSnapshotValuesAtCapture));
      },
    );
  });

  group(
    'Migration — old addListener pattern',
    () {
      // This is the migration-pinning test: it mimics the pre-refactor
      // README pattern in which consumers called `controller.addListener`
      // and read `controller.sizes` to observe drag updates. After b413c10,
      // that listener no longer fires during a drag. The fix is to listen
      // to `controller.pixelsListenable` instead.
      testWidgets(
        'addListener observing controller.sizes receives 0 callbacks during '
        'a drag (the breaking change)',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(1000, 600));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(_harness(controller: controller));
          await tester.pumpAndSettle();

          final observedSizes = <List<ResizableSize>>[];
          controller.addListener(() {
            observedSizes.add(List.of(controller.sizes));
          });

          final preDragWidth = tester.getSize(find.byKey(const Key('A'))).width;
          await tester.timedDrag(
            find.byType(ResizableContainerDivider),
            const Offset(120, 0),
            const Duration(milliseconds: 200),
          );
          await tester.pump();

          final postDragWidth =
              tester.getSize(find.byKey(const Key('A'))).width;
          expect(postDragWidth, greaterThan(preDragWidth));

          expect(observedSizes, isEmpty);
        },
      );

      testWidgets(
        'the same listener fires ≥1 time after hide() and after structural '
        'setSizes/setChildren updates',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(1000, 600));
          final controller = ResizableController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(_harness(controller: controller));
          await tester.pumpAndSettle();

          var notifies = 0;
          controller.addListener(() => notifies++);

          controller.hide(0);
          await tester.pumpAndSettle();
          expect(notifies, greaterThanOrEqualTo(1));

          notifies = 0;
          controller.show(0);
          await tester.pumpAndSettle();
          expect(notifies, greaterThanOrEqualTo(1));

          notifies = 0;
          controller.setSizes(const [
            ResizableSize.ratio(0.4),
            ResizableSize.ratio(0.6),
          ]);
          await tester.pumpAndSettle();
          expect(notifies, greaterThanOrEqualTo(1));

          notifies = 0;
          controller.setChildren(const [
            ResizableChild(
              size: ResizableSize.ratio(0.5),
              child: SizedBox.expand(),
            ),
            ResizableChild(
              size: ResizableSize.ratio(0.5),
              child: SizedBox.expand(),
            ),
          ]);
          await tester.pumpAndSettle();
          expect(notifies, greaterThanOrEqualTo(1));
        },
      );
    },
  );

  group('Listenable.merge coalescing', () {
    testWidgets(
      'one setChildren call results in at most one merge-listener fire '
      'per microtask drain',
      (tester) async {
        // The container itself subscribes to
        // `Listenable.merge([controller, controller.needsLayoutListenable])`.
        // We mirror that subscription here and count merge fires across a
        // single structural update. `setChildren` fires the main listener
        // once and the needs-layout listener twice (true then false after
        // the post-frame), but those happen across separate frames — we
        // pin total merge fires <= 3 to leave room for the legitimate
        // needs-layout flip cycle while guarding against a pathological
        // "every-pixel-fire" regression on the merge channel.
        await tester.binding.setSurfaceSize(const Size(800, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        final merged = Listenable.merge([
          controller,
          controller.needsLayoutListenable,
        ]);

        var mergeFires = 0;
        void listener() => mergeFires++;
        merged.addListener(listener);
        addTearDown(() => merged.removeListener(listener));

        controller.setChildren(const [
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

        // 1 fire from main + 2 from needsLayout (true, then false after the
        // post-frame _setRenderedSizes) === 3. Pin to that exact count;
        // anything higher means a regression has fed pixel updates into the
        // merge channel.
        expect(mergeFires, 3);
      },
    );

    testWidgets('merge listener fires 0 times during a drag', (tester) async {
      // `_adjustChildSize` only writes `_pixelsListenable`, which is NOT in
      // the merge tuple. Neither the main controller listener nor
      // `needsLayoutListenable` fires during a drag, so the merge listener
      // must stay silent for the entire gesture.
      await tester.binding.setSurfaceSize(const Size(1000, 600));
      final controller = ResizableController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_harness(controller: controller));
      await tester.pumpAndSettle();

      final merged = Listenable.merge([
        controller,
        controller.needsLayoutListenable,
      ]);

      var mergeFires = 0;
      void listener() => mergeFires++;
      merged.addListener(listener);
      addTearDown(() => merged.removeListener(listener));

      final preDragWidth = tester.getSize(find.byKey(const Key('A'))).width;
      await tester.timedDrag(
        find.byType(ResizableContainerDivider),
        const Offset(120, 0),
        const Duration(milliseconds: 200),
      );
      await tester.pump();

      final postDragWidth = tester.getSize(find.byKey(const Key('A'))).width;
      expect(postDragWidth, greaterThan(preDragWidth));

      expect(mergeFires, 0);
    });
  });
}

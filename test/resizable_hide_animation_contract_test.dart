// Pins the listener-and-build-path contract for `ResizableContainer.hideAnimation`
// (b102ae9 + the dual-path refactor in PR #134).
//
// Key finding — the animation lives in the widget, not the controller:
//
//   * `ResizableController.hide(index)` / `show(index)` are synchronous calls
//     that flip the hidden set, set `needsLayout = true`, and fire the main
//     listener exactly once. They do NOT animate.
//   * `HideAnimationCoordinator` (owned by `_ResizableContainerState`) drives
//     the cross-frame tween via `AnimationController` + `setState`. The
//     controller is untouched during the animation.
//
// Consequently, the listener cadence across an animated hide/show is NOT
// "once per animated frame" on `pixelsListenable`:
//
//   * `mainNotifies` fires exactly 1× per hide/show call, regardless of
//     whether the animation is configured.
//   * `pixelsListenable` fires at structural boundaries only:
//       - once when `hide()`/`show()` republishes pixels (the "capturing"
//         pre-flight);
//       - once from `_captureTarget`'s post-frame `setRenderedSizes` (publishes
//         the measured target and flips `needsLayout` → false);
//       - once after the animation completes when idle re-enters `_buildLayout`
//         and the post-frame `_scheduleSetRenderedSizes` fires.
//     So the realistic upper bound is ~3 pixel notifies for one animated
//     hide(), NOT one per frame.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_test/flutter_test.dart';

const _animationDuration = Duration(milliseconds: 300);
const _hideAnimation = ResizableHideAnimation(duration: _animationDuration);

Widget _harness({
  required ResizableController controller,
  Axis direction = Axis.horizontal,
  List<ResizableChild>? children,
  ResizableHideAnimation? hideAnimation = _hideAnimation,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ResizableContainer(
        controller: controller,
        direction: direction,
        hideAnimation: hideAnimation,
        children: children ??
            const [
              ResizableChild(
                size: ResizableSize.ratio(0.34),
                child: SizedBox.expand(key: Key('A')),
              ),
              ResizableChild(
                size: ResizableSize.ratio(0.33),
                child: SizedBox.expand(key: Key('B')),
              ),
              ResizableChild(
                size: ResizableSize.ratio(0.33),
                child: SizedBox.expand(key: Key('C')),
              ),
            ],
      ),
    ),
  );
}

/// Pumps frames at a fixed cadence across at least [total]. Returns the
/// number of frames pumped.
Future<int> _pumpAcross(
  WidgetTester tester,
  Duration total, {
  Duration frame = const Duration(milliseconds: 16),
}) async {
  var elapsed = Duration.zero;
  var frames = 0;
  while (elapsed < total) {
    await tester.pump(frame);
    elapsed += frame;
    frames++;
  }
  return frames;
}

void main() {
  group('hide() with hideAnimation configured', () {
    testWidgets(
      'mainNotifies fires exactly once across the full animation '
      '(the initial hide call; not per animated frame)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        var mainNotifies = 0;
        controller.addListener(() => mainNotifies++);

        controller.hide(0);
        // Span the full animation duration with frame-cadence pumps.
        await _pumpAcross(tester, _animationDuration * 1.5);
        await tester.pumpAndSettle();

        expect(mainNotifies, 1);
      },
    );

    testWidgets(
      'pixelsListenable fires a small bounded number of times across the '
      'animation (NOT once-per-frame — the animation drives setState in the '
      'widget, not pixel writes on the controller)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        var pixelsNotifies = 0;
        controller.pixelsListenable.addListener(() => pixelsNotifies++);

        controller.hide(0);
        await _pumpAcross(tester, _animationDuration * 1.5);
        await tester.pumpAndSettle();

        // Observed cadence: ~3 fires total
        //   1. hide() republishes pixels (synchronous);
        //   2. _captureTarget's post-frame setRenderedSizes;
        //   3. post-animation _scheduleSetRenderedSizes after idle re-entry.
        // Pin a generous upper bound that still rules out per-frame regression
        // (300ms / 16ms ≈ 18 frames; per-frame regression would land ≥18).
        expect(
          pixelsNotifies,
          lessThanOrEqualTo(6),
          reason: 'per-frame pixel writes would push this far higher',
        );
        // Sanity: at least one structural pixel publish occurred.
        expect(pixelsNotifies, greaterThanOrEqualTo(1));
      },
    );

    testWidgets(
      'final state after hide completes: needsLayout=false, hidden child '
      'pixel is 0, hiddenIndices contains the index',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        controller.hide(0);
        await _pumpAcross(tester, _animationDuration * 1.5);
        await tester.pumpAndSettle();

        expect(controller.needsLayoutListenable.value, isFalse);
        expect(controller.isHidden(0), isTrue);
        expect(controller.pixels[0], 0);
      },
    );

    testWidgets(
      'drag on a non-adjacent divider during a hide animation: animation '
      'completes, mainNotifies still 1, no exceptions thrown',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        var mainNotifies = 0;
        controller.addListener(() => mainNotifies++);

        controller.hide(0);
        // Give the capture phase a couple of frames to settle into animating.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        // Drag the divider between B (index 1) and C (index 2). With child 0
        // hidden, divider 0 is hidden too, so divider 1 is the only
        // interactive one and is found via `find.byType(...).at(0)` — but
        // during animation the layout renders via _flexFromFullSizes which
        // builds dividers as ResizableContainerDivider as well. We allow the
        // drag to land on whichever divider is hit-testable.
        final dividers = find.byType(ResizableContainerDivider);
        if (dividers.evaluate().isNotEmpty) {
          await tester.timedDrag(
            dividers.first,
            const Offset(40, 0),
            const Duration(milliseconds: 60),
          );
        }

        await _pumpAcross(tester, _animationDuration * 1.5);
        await tester.pumpAndSettle();

        // The hide animation should still complete to its terminal state.
        expect(controller.isHidden(0), isTrue);
        expect(controller.pixels[0], 0);
        // A drag does NOT fire the main listener (drag flows through
        // pixelsListenable only). So mainNotifies stays at 1.
        expect(mainNotifies, 1);
      },
    );
  });

  group('show() with hideAnimation configured (symmetric)', () {
    testWidgets(
      'mainNotifies fires exactly once across the full show animation',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        controller.hide(0);
        await _pumpAcross(tester, _animationDuration * 1.5);
        await tester.pumpAndSettle();

        var mainNotifies = 0;
        controller.addListener(() => mainNotifies++);

        controller.show(0);
        await _pumpAcross(tester, _animationDuration * 1.5);
        await tester.pumpAndSettle();

        expect(mainNotifies, 1);
      },
    );

    testWidgets(
      'pixelsListenable stays bounded across a show animation (same cadence '
      'as hide — not per-frame)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        controller.hide(0);
        await _pumpAcross(tester, _animationDuration * 1.5);
        await tester.pumpAndSettle();

        var pixelsNotifies = 0;
        controller.pixelsListenable.addListener(() => pixelsNotifies++);

        controller.show(0);
        await _pumpAcross(tester, _animationDuration * 1.5);
        await tester.pumpAndSettle();

        expect(pixelsNotifies, lessThanOrEqualTo(6));
        expect(pixelsNotifies, greaterThanOrEqualTo(1));
      },
    );

    testWidgets(
      'final state after show completes: child is no longer hidden, pixel > 0',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        controller.hide(0);
        await _pumpAcross(tester, _animationDuration * 1.5);
        await tester.pumpAndSettle();

        controller.show(0);
        await _pumpAcross(tester, _animationDuration * 1.5);
        await tester.pumpAndSettle();

        expect(controller.isHidden(0), isFalse);
        expect(controller.needsLayoutListenable.value, isFalse);
        expect(controller.pixels[0], greaterThan(0));
      },
    );
  });

  group('sequential hide/show/hide during one animation', () {
    testWidgets(
      'three back-to-back calls: mainNotifies = 3 (one per call), no '
      'exceptions, final state matches the last call (hidden)',
      (tester) async {
        // Pins the reversal-mid-flight behavior the coordinator handles via
        // `beginCapture`. We do not assert anything about the exact tween
        // values — only that the controller bookkeeping is correct and the
        // final state is consistent with the last call.
        await tester.binding.setSurfaceSize(const Size(900, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        var mainNotifies = 0;
        controller.addListener(() => mainNotifies++);

        controller.hide(0);
        await tester.pump(const Duration(milliseconds: 50));
        controller.show(0);
        await tester.pump(const Duration(milliseconds: 50));
        controller.hide(0);
        await _pumpAcross(tester, _animationDuration * 2);
        await tester.pumpAndSettle();

        expect(mainNotifies, 3);
        expect(controller.isHidden(0), isTrue);
        expect(controller.pixels[0], 0);
        expect(controller.needsLayoutListenable.value, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('build-path coherence across animation phases', () {
    testWidgets(
      'needsLayoutListenable settles to false after a hide animation '
      'completes (the live-path is restored once idle re-enters)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_harness(controller: controller));
        await tester.pumpAndSettle();

        final needsLayoutValues = <bool>[];
        controller.needsLayoutListenable.addListener(() {
          needsLayoutValues.add(controller.needsLayoutListenable.value);
        });

        controller.hide(0);
        await _pumpAcross(tester, _animationDuration * 1.5);
        await tester.pumpAndSettle();

        // The listener must have seen at least one transition and settled at
        // false. Exact count is implementation-specific (capture pass + post-
        // animation re-entry both write needsLayout); pin the terminal state.
        expect(needsLayoutValues, isNotEmpty);
        expect(needsLayoutValues.last, isFalse);
        expect(controller.needsLayoutListenable.value, isFalse);
      },
    );

    testWidgets(
      'when hideAnimation is null, hide() snaps in a single frame and the '
      'observable listener cadence matches the existing contract test '
      '(this is the control case)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 600));
        final controller = ResizableController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _harness(controller: controller, hideAnimation: null),
        );
        await tester.pumpAndSettle();

        var mainNotifies = 0;
        var pixelsNotifies = 0;
        controller.addListener(() => mainNotifies++);
        controller.pixelsListenable.addListener(() => pixelsNotifies++);

        controller.hide(0);
        await tester.pumpAndSettle();

        expect(mainNotifies, 1);
        // Without an animation, the cadence is still bounded (hide publishes
        // pixels once + post-frame setRenderedSizes publishes once).
        expect(pixelsNotifies, lessThanOrEqualTo(4));
        expect(controller.isHidden(0), isTrue);
        expect(controller.pixels[0], 0);
        // Sanity that the snap path leaves needsLayout settled.
        expect(controller.needsLayoutListenable.value, isFalse);
        // Verify no listEquals dependency: the test purely counts and reads.
        debugDefaultTargetPlatformOverride = null;
      },
    );
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_resizable_container/src/hide_animation_coordinator.dart';
import 'package:flutter_resizable_container/src/resizable_hide_animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(HideAnimationCoordinator, () {
    late HideAnimationCoordinator coordinator;
    late int changes;

    const animation = ResizableHideAnimation(
      duration: Duration(milliseconds: 100),
      curve: Curves.linear,
    );

    setUp(() {
      changes = 0;
      coordinator = HideAnimationCoordinator(
        vsync: const TestVSync(),
        onChanged: () => changes++,
      );
    });

    tearDown(() => coordinator.dispose());

    group('beginCapture', () {
      test('keeps the pending from-snapshot when called while capturing', () {
        coordinator
          ..beginCapture([10, 1, 20])
          ..beginCapture([99, 99, 99]);

        expect(coordinator.currentSizes, [10, 1, 20]);
      });
    });

    group('claimTargetSlot', () {
      test('returns false when idle', () {
        expect(coordinator.phase, HideAnimationPhase.idle);
        expect(coordinator.claimTargetSlot(), isFalse);
      });

      test('returns true at most once per capture', () {
        coordinator.beginCapture([10, 1, 20]);

        expect(coordinator.phase, HideAnimationPhase.capturing);
        expect(coordinator.claimTargetSlot(), isTrue);
        expect(coordinator.claimTargetSlot(), isFalse);
        expect(coordinator.claimTargetSlot(), isFalse);
      });

      test('returns false while animating', () {
        coordinator
          ..beginCapture([10, 1, 20])
          ..startAnimation(target: [0, 0, 31], animation: animation);

        expect(coordinator.phase, HideAnimationPhase.animating);
        expect(coordinator.claimTargetSlot(), isFalse);
      });

      test('stays claimed when a new capture begins without a reset', () {
        coordinator.beginCapture([10, 1, 20]);
        expect(coordinator.claimTargetSlot(), isTrue);

        coordinator.beginCapture([10, 1, 20]);
        expect(coordinator.claimTargetSlot(), isFalse);
      });

      test('re-arms after startAnimation and a new capture', () {
        coordinator.beginCapture([10, 1, 20]);
        expect(coordinator.claimTargetSlot(), isTrue);

        coordinator.startAnimation(target: [0, 0, 31], animation: animation);
        coordinator.beginCapture([0, 0, 31]);

        expect(coordinator.phase, HideAnimationPhase.capturing);
        expect(coordinator.claimTargetSlot(), isTrue);
        expect(coordinator.claimTargetSlot(), isFalse);
      });

      test('re-arms after cancel and a new capture', () {
        coordinator.beginCapture([10, 1, 20]);
        expect(coordinator.claimTargetSlot(), isTrue);

        coordinator.cancel();
        expect(coordinator.phase, HideAnimationPhase.idle);
        expect(coordinator.claimTargetSlot(), isFalse);

        coordinator.beginCapture([10, 1, 20]);
        expect(coordinator.claimTargetSlot(), isTrue);
      });

      test('re-arms after reset and a new capture', () {
        coordinator.beginCapture([10, 1, 20]);
        expect(coordinator.claimTargetSlot(), isTrue);

        coordinator.reset();
        expect(coordinator.claimTargetSlot(), isFalse);

        coordinator.beginCapture([10, 1, 20]);
        expect(coordinator.claimTargetSlot(), isTrue);
      });

      test('startAnimation without a capture does not claim or animate', () {
        coordinator.startAnimation(target: [0, 0, 31], animation: animation);

        expect(coordinator.phase, HideAnimationPhase.idle);
        expect(coordinator.claimTargetSlot(), isFalse);
      });
    });

    group('lifecycle', () {
      testWidgets('returns to idle when the animation completes', (
        tester,
      ) async {
        coordinator
          ..beginCapture([10, 1, 20])
          ..startAnimation(target: [0, 0, 31], animation: animation);

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();

        expect(coordinator.phase, HideAnimationPhase.idle);
        expect(coordinator.currentSizes, isNull);
        expect(changes, greaterThan(0));
        expect(coordinator.claimTargetSlot(), isFalse);
      });
    });
  });
}

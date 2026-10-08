import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_resizable_container/src/hidden_child_scope.dart';
import 'package:flutter_test/flutter_test.dart';

class _Probe extends StatefulWidget {
  const _Probe({required this.focusNode});

  final FocusNode focusNode;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with SingleTickerProviderStateMixin {
  static int initCount = 0;

  late final Ticker ticker;
  bool tickerModeEnabled = true;

  @override
  void initState() {
    super.initState();
    initCount++;
    ticker = createTicker((_) {})..start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    tickerModeEnabled = TickerMode.valuesOf(context).enabled;
    return Focus(focusNode: widget.focusNode, child: const SizedBox());
  }
}

class _Harness extends StatelessWidget {
  const _Harness({
    required this.hidden,
    required this.tickersEnabled,
    required this.focusNode,
  });

  final bool hidden;
  final bool tickersEnabled;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: HiddenChildScope(
        hidden: hidden,
        tickersEnabled: tickersEnabled,
        child: _Probe(focusNode: focusNode),
      ),
    );
  }
}

void main() {
  group(HiddenChildScope, () {
    late FocusNode childNode;

    setUp(() {
      _ProbeState.initCount = 0;
      childNode = FocusNode(debugLabel: 'child');
    });

    tearDown(() => childNode.dispose());

    Future<void> pumpScope(
      WidgetTester tester, {
      required bool hidden,
      required bool tickersEnabled,
    }) {
      return tester.pumpWidget(
        _Harness(
          hidden: hidden,
          tickersEnabled: tickersEnabled,
          focusNode: childNode,
        ),
      );
    }

    testWidgets('keeps the child focusable while visible', (tester) async {
      await pumpScope(tester, hidden: false, tickersEnabled: true);

      childNode.requestFocus();
      await tester.pump();

      expect(childNode.hasPrimaryFocus, isTrue);
      expect(childNode.canRequestFocus, isTrue);
    });

    testWidgets('releases focus held inside when hidden', (tester) async {
      await pumpScope(tester, hidden: false, tickersEnabled: true);
      childNode.requestFocus();
      await tester.pump();
      expect(childNode.hasPrimaryFocus, isTrue);

      await pumpScope(tester, hidden: true, tickersEnabled: true);
      await tester.pump();

      expect(childNode.hasFocus, isFalse);
    });

    testWidgets('prevents the hidden child from taking focus', (tester) async {
      await pumpScope(tester, hidden: true, tickersEnabled: true);

      childNode.requestFocus();
      await tester.pump();

      expect(childNode.canRequestFocus, isFalse);
      expect(childNode.hasFocus, isFalse);
    });

    testWidgets('restores focusability when shown again', (tester) async {
      await pumpScope(tester, hidden: true, tickersEnabled: true);
      await pumpScope(tester, hidden: false, tickersEnabled: true);

      childNode.requestFocus();
      await tester.pump();

      expect(childNode.canRequestFocus, isTrue);
      expect(childNode.hasPrimaryFocus, isTrue);
    });

    testWidgets('never takes focus itself', (tester) async {
      await pumpScope(tester, hidden: false, tickersEnabled: true);

      final scopeFocus = Focus.of(tester.element(find.byType(_Probe)));

      expect(scopeFocus.canRequestFocus, isFalse);
      expect(scopeFocus.skipTraversal, isTrue);
    });

    testWidgets('disables tickers without remounting the child', (
      tester,
    ) async {
      await pumpScope(tester, hidden: false, tickersEnabled: true);
      final state = tester.state<_ProbeState>(find.byType(_Probe));
      expect(state.tickerModeEnabled, isTrue);
      expect(state.ticker.muted, isFalse);

      await pumpScope(tester, hidden: true, tickersEnabled: false);

      expect(tester.state<_ProbeState>(find.byType(_Probe)), same(state));
      expect(state.tickerModeEnabled, isFalse);
      expect(state.ticker.muted, isTrue);
      expect(_ProbeState.initCount, 1);

      await pumpScope(tester, hidden: false, tickersEnabled: true);

      expect(tester.state<_ProbeState>(find.byType(_Probe)), same(state));
      expect(state.tickerModeEnabled, isTrue);
      expect(state.ticker.muted, isFalse);
      expect(_ProbeState.initCount, 1);
    });

    testWidgets('keeps tickers running while hidden but not collapsed', (
      tester,
    ) async {
      await pumpScope(tester, hidden: false, tickersEnabled: true);
      final state = tester.state<_ProbeState>(find.byType(_Probe));

      await pumpScope(tester, hidden: true, tickersEnabled: true);

      expect(state.tickerModeEnabled, isTrue);
      expect(state.ticker.muted, isFalse);
      expect(_ProbeState.initCount, 1);
    });

    testWidgets('preserves child state when only focus flags change', (
      tester,
    ) async {
      await pumpScope(tester, hidden: false, tickersEnabled: true);
      final state = tester.state<_ProbeState>(find.byType(_Probe));

      await pumpScope(tester, hidden: true, tickersEnabled: true);
      await tester.pump();

      expect(tester.state<_ProbeState>(find.byType(_Probe)), same(state));
      expect(_ProbeState.initCount, 1);
    });
  });
}

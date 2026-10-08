import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Keeps a hidden child out of focus traversal and, once it has fully
/// collapsed, stops its tickers.
///
/// The widgets are always in the tree and only their flags change, so
/// toggling [hidden] never remounts [child].
class HiddenChildScope extends StatefulWidget {
  const HiddenChildScope({
    super.key,
    required this.hidden,
    required this.tickersEnabled,
    required this.child,
  });

  final bool hidden;
  final bool tickersEnabled;
  final Widget child;

  @override
  State<HiddenChildScope> createState() => _HiddenChildScopeState();
}

class _HiddenChildScopeState extends State<HiddenChildScope> {
  final _focusNode = FocusNode(
    skipTraversal: true,
    canRequestFocus: false,
    debugLabel: 'HiddenChildScope',
  );

  @override
  void initState() {
    super.initState();
    _releaseFocusIfHidden();
  }

  @override
  void didUpdateWidget(covariant HiddenChildScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.hidden) _releaseFocusIfHidden();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // A child that was focused when it was hidden is remounted under an already
  // excluded node, which keeps its primary focus unless it is released here.
  void _releaseFocusIfHidden() {
    if (!widget.hidden) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.hidden && _focusNode.hasFocus) {
        _focusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      descendantsAreFocusable: !widget.hidden,
      child: TickerMode(
        enabled: widget.tickersEnabled,
        child: widget.child,
      ),
    );
  }
}

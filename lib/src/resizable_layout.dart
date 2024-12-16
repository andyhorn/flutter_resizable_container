import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/layout_key.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_resizable_container/src/resizable_layout_delegate.dart';

class ResizableLayout extends StatelessWidget {
  const ResizableLayout({
    super.key,
    required this.children,
    required this.direction,
    required this.divider,
    required this.onLayoutComplete,
  });

  final List<ResizableChild> children;
  final Axis direction;
  final ResizableDivider divider;
  final Function(List<double>) onLayoutComplete;

  @override
  Widget build(BuildContext context) {
    return CustomMultiChildLayout(
      delegate: _getLayoutDelegate(),
      children: [
        for (var i = 0; i < children.length; i++) ...[
          LayoutId(
            id: ChildKey(i),
            child: children[i].child,
          ),
          if (i < children.length - 1) ...[
            LayoutId(
              id: DividerKey(i),
              child: ResizableContainerDivider(
                config: divider,
                direction: direction,
                onResizeUpdate: (_) {},
              ),
            ),
          ],
        ],
      ],
    );
  }

  ResizableLayoutDelegate _getLayoutDelegate() {
    final dividers = List.generate(children.length - 1, (i) => divider);

    return switch (direction) {
      Axis.vertical => ResizableLayoutDelegate.vertical(
          children: children,
          dividers: dividers,
          onLayoutComplete: onLayoutComplete,
        ),
      Axis.horizontal => ResizableLayoutDelegate.horizontal(
          children: children,
          dividers: dividers,
          onLayoutComplete: onLayoutComplete,
        ),
    };
  }
}

import 'package:flutter_resizable_container/src/layout/resizable_allocation.dart';
import 'package:flutter_resizable_container/src/resizable_child.dart';

/// The total main-axis space taken by the visible dividers between [children].
double getDividerSpace(
  List<ResizableChild> children,
  Set<int> hiddenIndices,
) {
  var total = 0.0;
  for (var i = 0; i < children.length - 1; i++) {
    total += dividerExtent(children[i].divider, hiddenIndices, i);
  }
  return total;
}

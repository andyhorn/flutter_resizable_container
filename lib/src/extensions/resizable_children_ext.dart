import 'package:flutter_resizable_container/src/resizable_child.dart';
import 'package:flutter_resizable_container/src/resizable_divider.dart';

extension ResizableChildrenExtensions on List<ResizableChild> {
  /// The divider that follows each child except the last.
  List<ResizableDivider> get dividers => [
        for (var i = 0; i < length - 1; i++) this[i].divider,
      ];

  /// Whether [other] has the same number of children, each with the same
  /// declared size and key.
  bool hasSameStructureAs(List<ResizableChild> other) {
    if (length != other.length) {
      return false;
    }
    for (var i = 0; i < length; i++) {
      if (this[i].size != other[i].size || this[i].key != other[i].key) {
        return false;
      }
    }
    return true;
  }
}

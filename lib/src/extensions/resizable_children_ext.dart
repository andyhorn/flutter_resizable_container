import 'package:flutter_resizable_container/src/resizable_child.dart';
import 'package:flutter_resizable_container/src/resizable_divider.dart';

extension ResizableChildrenExtensions on List<ResizableChild> {
  /// The divider that follows each child except the last.
  List<ResizableDivider> get dividers => [
        for (var i = 0; i < length - 1; i++) this[i].divider,
      ];
}

import 'package:flutter/material.dart';

import "resizable_child_data.dart";
import "resizable_container.dart";
import "utils.dart";

/// A controller to provide a programmatic interface to a [ResizableContainer].
class ResizableController with ChangeNotifier {
  /// The sizes in pixels of each child.
  final List<double> sizes = [];

  /// The total available space for this container in the given axis.
  double availableSpace = -1;

  /// The number of resizable children this container has.
  int get numChildren => sizes.length;

  /// The ratios of all the children, like [ResizableChildData.startingRatio].
  List<double> get ratios => [
        for (final size in sizes) size / availableSpace,
      ];

  /// Programmatically set the ratios on the children. See [ratios] to get their current ratios.
  void setRatios(List<double> values) {
    if (values.length != numChildren) {
      throw ArgumentError(
        "Ratios list must be equal to the number of children",
      );
    }

    if (sum(values) != 1) {
      throw ArgumentError("The sum of the ratios must equal 1");
    }

    for (var i = 0; i < numChildren; i++) {
      sizes[i] = values[i] * availableSpace;
    }

    notifyListeners();
  }
}

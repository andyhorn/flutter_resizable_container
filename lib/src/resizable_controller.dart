import 'package:flutter/material.dart';

class ResizableController with ChangeNotifier {
  final List<double> sizes = [];
  double availableSpace = -1;
  
  int get numChildren => sizes.length;

  List<double> get ratios => [
    for (final size in sizes)
      size / availableSpace,
  ];

  void setRatios(List<double> values) {
    if (values.length != numChildren) throw ArgumentError("Ratios list must be equal to the number of children");
    if (sum(values) != 1) throw ArgumentError("The sum of the ratios must equal 1");
    for (var i = 0; i < numChildren; i++) {
      sizes[i] = values[i] * availableSpace;
    }
    notifyListeners();
  }
}

num sum(List<num> list) {
  num result = 0;
  for (final element in list) {
    result += element;
  }
  return result;
}

extension IterableNumExtensions on Iterable<num> {
  num sum() => fold(0, (sum, current) => sum + current);
}

extension IterableExtensions on Iterable {
  int nullCount() => where((item) => item == null).length;
}

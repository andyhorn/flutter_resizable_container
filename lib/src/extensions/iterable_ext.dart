extension IterableNumExtensions on Iterable<num> {
  num sum() => fold(0, (sum, current) => sum + current);
}

extension IterableExtensions<T> on Iterable<T> {
  int nullCount() => where((item) => item == null).length;

  int count(bool Function(T) test) => where(test).length;

  num sum(num Function(T) extractor) => fold(
        0.0,
        (sum, current) => sum + extractor(current),
      );

  Iterable<T> evenIndices() => [
        for (var i = 0; i < length; i++) ...[
          if (i % 2 == 0) ...[
            elementAt(i),
          ],
        ],
      ];
}

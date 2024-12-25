extension IterableExtensions<T> on Iterable<T> {
  int nullCount() => where((item) => item == null).length;

  int count(bool Function(T) test) => where(test).length;

  Iterable<T> evenIndices() => [
        for (var i = 0; i < length; i++) ...[
          if (i % 2 == 0) ...[
            elementAt(i),
          ],
        ],
      ];
}

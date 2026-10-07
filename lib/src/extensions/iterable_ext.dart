extension IterableExtensions<T> on Iterable<T> {
  Iterable<T> evenIndices() => [
        for (var i = 0; i < length; i++) ...[
          if (i % 2 == 0) ...[
            elementAt(i),
          ],
        ],
      ];

  Iterable<int> indicesWhere(bool Function(T) test) => [
        for (var i = 0; i < length; i++) ...[
          if (test(elementAt(i))) ...[
            i,
          ],
        ],
      ];
}

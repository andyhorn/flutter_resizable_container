sealed class LayoutKey {
  const LayoutKey._(this.key);

  final String key;

  @override
  String toString() => key;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LayoutKey && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}

final class ChildKey extends LayoutKey {
  ChildKey(int i) : super._('child_$i');
}

final class DividerKey extends LayoutKey {
  DividerKey(int i) : super._('divider_$i');
}

/// Returns the sum of a list.
num sum(List<num> list) {
  num result = 0;
  for (final element in list) {
    result += element;
  }
  return result;
}

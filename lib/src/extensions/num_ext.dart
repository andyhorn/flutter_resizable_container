import 'package:decimal/decimal.dart';

extension DoubleExtensions on double {
  Decimal toDecimal() => Decimal.parse(toString());
}

extension LisDoubleExtensions on Iterable<double> {
  double sum() => fold(0.0, (sum, curr) => sum + curr);
}

extension ListIntExtensions on Iterable<int> {
  double sum() => fold(0, (sum, curr) => sum + curr);
}

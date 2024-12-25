import 'package:decimal/decimal.dart';

extension DoubleExtensions on double {
  Decimal toDecimal() => Decimal.parse(toString());
}

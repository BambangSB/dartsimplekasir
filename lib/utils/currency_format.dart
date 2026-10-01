import 'package:intl/intl.dart';

class CurrencyFormat {
  static String toRupiah(num val) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(val);
  }
}

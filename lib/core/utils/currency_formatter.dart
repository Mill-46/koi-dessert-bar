import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _rupiahFormat = NumberFormat.decimalPattern('id_ID');

  static String rupiah(num amount) {
    return 'Rp ${_rupiahFormat.format(amount.round())}';
  }
}

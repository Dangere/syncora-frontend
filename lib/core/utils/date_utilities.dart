import 'package:intl/intl.dart';

class DateUtilities {
  static String getFormattedDate(DateTime date) {
    String formatted = DateFormat('dd/MM/yyyy').format(date);
    return formatted;
  }
}

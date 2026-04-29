import 'package:intl/intl.dart';

String formatCurrency(num amount) => NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ').format(amount);

String formatDate(String? value) {
  if (value == null || value.isEmpty) {
    return '-';
  }

  final date = DateTime.tryParse(value);
  if (date == null) {
    return value;
  }

  return DateFormat('dd MMM yyyy').format(date);
}

String formatDateTime(String? value) {
  if (value == null || value.isEmpty) {
    return '-';
  }

  final date = DateTime.tryParse(value);
  if (date == null) {
    return value;
  }

  return DateFormat('dd MMM yyyy, hh:mm a').format(date);
}

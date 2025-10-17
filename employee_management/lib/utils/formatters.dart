import 'package:intl/intl.dart';

class Formatters {
  // Format tiền tệ VND
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Format ngày tháng DD/MM/YYYY
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  // Format ngày giờ DD/MM/YYYY HH:mm
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dateTime);
  }

  // Format số điện thoại
  static String formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    // Format: 0123 456 789
    if (phone.length == 10) {
      return '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7)}';
    }
    return phone;
  }

  // Format employee code
  static String formatEmployeeCode(String code) {
    return code.toUpperCase();
  }

  // Format percentage
  static String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  // Parse date from ISO string
  static DateTime? parseIsoDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return null;
    try {
      return DateTime.parse(isoDate);
    } catch (e) {
      return null;
    }
  }

  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

import 'package:intl/intl.dart';

/// 🌏 Vietnam TimeZone Utility
/// 
/// Quản lý múi giờ Việt Nam (UTC+7) một cách nhất quán với backend
/// Backend sử dụng: SE Asia Standard Time (UTC+7)
/// 
/// Features:
/// - Convert UTC to Vietnam time
/// - Format dates in Vietnamese format
/// - Consistent timezone handling across the app
class VietnamTimeZone {
  /// Vietnam timezone offset: UTC+7
  static const Duration vietnamOffset = Duration(hours: 7);
  
  /// Vietnamese locale identifier
  static const String vietnamLocale = 'vi_VN';
  
  /// Common date/time formatters for Vietnamese
  static final DateFormat dateFormat = DateFormat('dd/MM/yyyy', vietnamLocale);
  static final DateFormat timeFormat = DateFormat('HH:mm:ss', vietnamLocale);
  static final DateFormat dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm:ss', vietnamLocale);
  static final DateFormat dateTimeShortFormat = DateFormat('dd/MM/yyyy HH:mm', vietnamLocale);
  static final DateFormat dayDateFormat = DateFormat('EEEE, dd/MM/yyyy', vietnamLocale);
  static final DateFormat monthYearFormat = DateFormat('MM/yyyy', vietnamLocale);
  static final DateFormat fullDateFormat = DateFormat('EEEE, dd MMMM yyyy', vietnamLocale);
  
  /// Get current Vietnam time (UTC+7)
  static DateTime now() {
    return DateTime.now().toUtc().add(vietnamOffset);
  }
  
  /// Convert UTC DateTime to Vietnam time
  static DateTime fromUtc(DateTime utcDateTime) {
    return utcDateTime.toUtc().add(vietnamOffset);
  }
  
  /// Convert Vietnam time to UTC
  static DateTime toUtc(DateTime vietnamDateTime) {
    return vietnamDateTime.subtract(vietnamOffset).toUtc();
  }
  
  /// Format DateTime to Vietnamese date string (dd/MM/yyyy)
  static String formatDate(DateTime dateTime, {bool useLocal = true}) {
    final vietnamTime = useLocal ? fromUtc(dateTime.toUtc()) : dateTime;
    return dateFormat.format(vietnamTime);
  }
  
  /// Format DateTime to Vietnamese time string (HH:mm:ss)
  static String formatTime(DateTime dateTime, {bool useLocal = true}) {
    final vietnamTime = useLocal ? fromUtc(dateTime.toUtc()) : dateTime;
    return timeFormat.format(vietnamTime);
  }
  
  /// Format DateTime to Vietnamese datetime string (dd/MM/yyyy HH:mm:ss)
  static String formatDateTime(DateTime dateTime, {bool useLocal = true}) {
    final vietnamTime = useLocal ? fromUtc(dateTime.toUtc()) : dateTime;
    return dateTimeFormat.format(vietnamTime);
  }
  
  /// Format DateTime to Vietnamese short datetime string (dd/MM/yyyy HH:mm)
  static String formatDateTimeShort(DateTime dateTime, {bool useLocal = true}) {
    final vietnamTime = useLocal ? fromUtc(dateTime.toUtc()) : dateTime;
    return dateTimeShortFormat.format(vietnamTime);
  }
  
  /// Format DateTime to Vietnamese day and date (Thứ Hai, 22/10/2025)
  static String formatDayDate(DateTime dateTime, {bool useLocal = true}) {
    final vietnamTime = useLocal ? fromUtc(dateTime.toUtc()) : dateTime;
    return dayDateFormat.format(vietnamTime);
  }
  
  /// Format DateTime to month/year (10/2025)
  static String formatMonthYear(DateTime dateTime, {bool useLocal = true}) {
    final vietnamTime = useLocal ? fromUtc(dateTime.toUtc()) : dateTime;
    return monthYearFormat.format(vietnamTime);
  }
  
  /// Format DateTime to full Vietnamese date (Thứ Hai, 22 tháng 10 năm 2025)
  static String formatFullDate(DateTime dateTime, {bool useLocal = true}) {
    final vietnamTime = useLocal ? fromUtc(dateTime.toUtc()) : dateTime;
    return fullDateFormat.format(vietnamTime);
  }
  
  /// Get start of day in Vietnam timezone
  static DateTime startOfDay(DateTime dateTime) {
    final vietnamTime = fromUtc(dateTime.toUtc());
    return DateTime(vietnamTime.year, vietnamTime.month, vietnamTime.day);
  }
  
  /// Get end of day in Vietnam timezone
  static DateTime endOfDay(DateTime dateTime) {
    final vietnamTime = fromUtc(dateTime.toUtc());
    return DateTime(vietnamTime.year, vietnamTime.month, vietnamTime.day, 23, 59, 59, 999);
  }
  
  /// Get start of month in Vietnam timezone
  static DateTime startOfMonth(DateTime dateTime) {
    final vietnamTime = fromUtc(dateTime.toUtc());
    return DateTime(vietnamTime.year, vietnamTime.month, 1);
  }
  
  /// Get end of month in Vietnam timezone
  static DateTime endOfMonth(DateTime dateTime) {
    final vietnamTime = fromUtc(dateTime.toUtc());
    final nextMonth = DateTime(vietnamTime.year, vietnamTime.month + 1, 1);
    return nextMonth.subtract(const Duration(milliseconds: 1));
  }
  
  /// Check if a date is today in Vietnam timezone
  static bool isToday(DateTime dateTime) {
    final vietnamTime = fromUtc(dateTime.toUtc());
    final today = now();
    return vietnamTime.year == today.year &&
           vietnamTime.month == today.month &&
           vietnamTime.day == today.day;
  }
  
  /// Get relative time description in Vietnamese
  static String getRelativeTime(DateTime dateTime) {
    final vietnamTime = fromUtc(dateTime.toUtc());
    final now = VietnamTimeZone.now();
    final difference = now.difference(vietnamTime);
    
    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 30) {
      final weeks = difference.inDays ~/ 7;
      return '$weeks tuần trước';
    } else if (difference.inDays < 365) {
      final months = difference.inDays ~/ 30;
      return '$months tháng trước';
    } else {
      final years = difference.inDays ~/ 365;
      return '$years năm trước';
    }
  }
  
  /// Parse ISO string to Vietnam DateTime
  static DateTime? parseIsoString(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    
    try {
      final utcDateTime = DateTime.parse(isoString);
      return fromUtc(utcDateTime);
    } catch (e) {
      return null;
    }
  }
  
  /// Convert DateTime to ISO string in UTC (for API calls)
  static String toIsoString(DateTime dateTime) {
    return toUtc(dateTime).toIso8601String();
  }
  
  /// Debug info about current time
  static Map<String, String> getDebugInfo() {
    final now = DateTime.now();
    final utcNow = now.toUtc();
    final vietnamNow = VietnamTimeZone.now();
    
    return {
      'Local Time': now.toString(),
      'UTC Time': utcNow.toString(),
      'Vietnam Time (UTC+7)': vietnamNow.toString(),
      'Formatted Vietnam': formatDateTime(vietnamNow, useLocal: false),
      'Offset Hours': '+7',
      'Locale': vietnamLocale,
    };
  }
}

/// Extension methods for DateTime to work with Vietnam timezone
extension DateTimeVietnamExtension on DateTime {
  /// Convert this DateTime to Vietnam time
  DateTime toVietnamTime() => VietnamTimeZone.fromUtc(toUtc());
  
  /// Format this DateTime as Vietnamese date
  String toVietnamDateString() => VietnamTimeZone.formatDate(this);
  
  /// Format this DateTime as Vietnamese time
  String toVietnamTimeString() => VietnamTimeZone.formatTime(this);
  
  /// Format this DateTime as Vietnamese datetime
  String toVietnamDateTimeString() => VietnamTimeZone.formatDateTime(this);
  
  /// Format this DateTime as Vietnamese short datetime
  String toVietnamDateTimeShortString() => VietnamTimeZone.formatDateTimeShort(this);
  
  /// Check if this DateTime is today in Vietnam timezone
  bool isVietnamToday() => VietnamTimeZone.isToday(this);
  
  /// Get relative time from now in Vietnam timezone
  String toVietnamRelativeTime() => VietnamTimeZone.getRelativeTime(this);
}
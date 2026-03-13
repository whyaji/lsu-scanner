import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class DateUtils {
  static final DateFormat _dateFormat = DateFormat(AppConstants.dateFormat);
  static final DateFormat _timeFormat = DateFormat(AppConstants.timeFormat);
  static final DateFormat _dateTimeFormat = DateFormat(
    AppConstants.dateTimeFormat,
  );

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  static DateTime? parseDate(String dateString) {
    try {
      return _dateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  static DateTime? parseTime(String timeString) {
    try {
      return _timeFormat.parse(timeString);
    } catch (e) {
      return null;
    }
  }

  static String getCurrentDate() {
    return formatDate(DateTime.now());
  }

  static String getCurrentTime() {
    return formatTime(DateTime.now());
  }

  static String getCurrentDateTime() {
    return formatDateTime(DateTime.now());
  }

  /// Returns current date and time as ISO 8601 string (UTC).
  /// Use for API payloads and local DB storage (API requires datetime with time).
  static String getCurrentIso8601DateTime() {
    return DateTime.now().toIso8601String();
  }

  /// Parses an ISO 8601 date string and formats it for display in local date+time.
  /// Returns '-' if [isoString] is null, empty, or invalid.
  static String formatDateTimeFromIso(String? isoString) {
    if (isoString == null || isoString.trim().isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoString);
      return _dateTimeFormat.format(dt);
    } catch (_) {
      return isoString;
    }
  }
}

import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class DateUtils {
  static final DateFormat _dateFormat = DateFormat(AppConstants.dateFormat);
  static final DateFormat _timeFormat = DateFormat(AppConstants.timeFormat);
  static final DateFormat _dateTimeFormat = DateFormat(
    AppConstants.dateTimeFormat,
  );
  static final DateFormat _dateDisplayFormat = DateFormat(
    AppConstants.dateDisplayFormat,
    AppConstants.uiDateLocale,
  );

  /// Calendar date for UI ([AppConstants.dateDisplayFormat], local timezone).
  static String formatDateForDisplay(DateTime date) {
    return _dateDisplayFormat.format(date.toLocal());
  }

  /// Parses ISO / storage date strings and formats the calendar date for UI.
  static String formatStoredDateForDisplay(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final dt = _parseFlexibleToLocal(raw);
    if (dt != null) return formatDateForDisplay(dt);
    final d = parseDate(raw.trim());
    if (d != null) return formatDateForDisplay(d);
    final fb = _normalizePupukDateRaw(raw);
    return fb.isEmpty ? '-' : fb;
  }

  /// Local date + time for UI (date uses [AppConstants.dateDisplayFormat]).
  static String formatDateTimeForDisplay(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${_dateDisplayFormat.format(local)} ${_timeFormat.format(local)}';
  }

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

  static String _normalizePupukDateRaw(String raw) {
    var s = raw.trim();
    while (s.length >= 2 &&
        ((s.startsWith('"') && s.endsWith('"')) ||
            (s.startsWith("'") && s.endsWith("'")))) {
      s = s.substring(1, s.length - 1).trim();
    }
    return s
        .replaceAll('\u2011', '-') // non-breaking hyphen
        .replaceAll('\u2212', '-'); // unicode minus
  }

  /// Parses ISO-ish API strings; [raw] may be wrapped in quotes or use odd unicode dashes.
  static DateTime? _parseFlexibleToLocal(String raw) {
    final s = _normalizePupukDateRaw(raw);
    if (s.isEmpty) return null;

    var direct = DateTime.tryParse(s);
    if (direct == null) {
      final t = s.indexOf('T');
      if (t > 0) {
        final tail = s.substring(t + 1);
        if (tail.contains(',') && !tail.contains('.')) {
          direct = DateTime.tryParse(
            '${s.substring(0, t + 1)}${tail.replaceFirst(',', '.')}',
          );
        }
      }
    }
    if (direct != null) return direct.toLocal();

    // Space between date and time (some backends omit 'T')
    if (s.contains(' ') && !s.contains('T')) {
      final spaced = s.replaceFirst(RegExp(r'\s+'), 'T');
      final dt = DateTime.tryParse(spaced);
      if (dt != null) return dt.toLocal();
    }

    // Leading calendar date before 'T' or space (handles cases tryParse rejects)
    final isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}').stringMatch(s);
    if (isoDate != null) {
      final d = parseDate(isoDate);
      if (d != null) return d;
    }

    return parseDate(s);
  }

  /// Formats API/sync date strings for pupuk detail rows ([AppConstants.dateDisplayFormat]).
  /// Accepts ISO 8601 and [AppConstants.dateFormat]; returns normalized text if unparsable.
  static String formatPupukDetailTanggal(String? raw) {
    return formatStoredDateForDisplay(raw);
  }

  /// Parses an ISO 8601 date string and formats it for display in local date+time.
  /// Returns '-' if [isoString] is null, empty, or invalid.
  static String formatDateTimeFromIso(String? isoString) {
    if (isoString == null || isoString.trim().isEmpty) return '-';
    final dt = _parseFlexibleToLocal(isoString);
    if (dt == null) return _normalizePupukDateRaw(isoString);
    return formatDateTimeForDisplay(dt);
  }
}

import 'package:intl/intl.dart';

extension StringExtensions on String {
  bool get isNumeric {
    final parsed = double.tryParse(trim());
    return parsed != null && parsed.isFinite;
  }

  bool get isIsoDate {
    final value = trim();
    if (value.length < 10) return false;
    final isoRegex = RegExp(
      r'^\d{4}-\d{2}-\d{2}([T ]\d{2}:\d{2}(:\d{2}(\.\d+)?)?(Z|[+-]\d{2}:?\d{2})?)?$',
    );
    if (!isoRegex.hasMatch(value)) return false;
    return DateTime.tryParse(value) != null;
  }

  String get formatIsoDateOrSelf {
    if (!isIsoDate) return this;
    try {
      final parsed = DateTime.parse(trim());
      if (trim().length == 10) {
        return DateFormat('yyyy-MM-dd').format(parsed);
      }
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(parsed);
    } catch (_) {
      return this;
    }
  }

  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  String get fileNameFromPath {
    final normalized = replaceAll(r'\', '/');
    return normalized.split('/').last;
  }
}

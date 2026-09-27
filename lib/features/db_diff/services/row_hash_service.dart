import 'dart:typed_data';

class RowHashService {
  RowHashService._();

  static int hashRow(Map<String, dynamic> row, List<String> columns) {
    var hash = 17;
    for (final col in columns) {
      final val = row[col];
      hash = 37 * hash + _hashValue(val);
    }
    return hash;
  }

  static int _hashValue(dynamic value) {
    if (value == null) return 0;
    if (value is Uint8List) {
      var blobHash = value.length;
      for (var i = 0; i < value.length; i++) {
        blobHash = (31 * blobHash + value[i]) & 0x7FFFFFFF;
      }
      return blobHash;
    }
    return value.hashCode;
  }

  static String canonicalRowString(
    Map<String, dynamic> row,
    List<String> columns,
  ) {
    final buffer = StringBuffer();
    for (final col in columns) {
      final val = row[col];
      if (val == null) {
        buffer.write('N;');
      } else if (val is int) {
        buffer.write('I:$val;');
      } else if (val is double) {
        buffer.write('F:$val;');
      } else if (val is Uint8List) {
        buffer.write('B:${val.length}:${val.join(',')};');
      } else if (val is String) {
        buffer.write('T:${val.length}:$val;');
      } else {
        final str = val.toString();
        buffer.write('O:${val.runtimeType}:${str.length}:$str;');
      }
    }
    return buffer.toString();
  }

  static String buildKeyString(
    Map<String, dynamic> row,
    List<String> pkColumns,
  ) {
    if (pkColumns.isEmpty) {
      return '';
    }
    return pkColumns
        .map((pk) {
          final val = row[pk];
          if (val == null) return 'N';
          if (val is int) return 'I:$val';
          if (val is double) return 'F:$val';
          if (val is Uint8List) return 'B:${val.length}:${val.join(',')}';
          if (val is String) return 'T:${val.length}:$val';
          final valStr = val.toString();
          return 'O:${val.runtimeType}:${valStr.length}:$valStr';
        })
        .join('\u001F');
  }

  static String buildKeyDisplay(
    Map<String, dynamic> row,
    List<String> pkColumns,
  ) {
    if (pkColumns.isEmpty) {
      return 'Row';
    }
    return pkColumns.map((pk) => '$pk: ${row[pk]}').join(', ');
  }
}

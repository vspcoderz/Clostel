const catalogAccentValues = [
  0xFFEB5E55,
  0xFFD81E5B,
  0xFFC6D8D3,
  0xFFFDF0D5,
  0xFF3A3335,
];

String? safeHttpUrl(Object? value) {
  final raw = stringValue(value).trim();
  if (raw.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(raw);
  if (uri == null ||
      (uri.scheme != 'https' && uri.scheme != 'http') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return raw;
}

String stringValue(Object? value) {
  if (value is String) {
    return value.trim();
  }
  if (value is num) {
    return value.toString();
  }
  return '';
}

Map<String, dynamic>? mapValue(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

int accentFor(String seed) =>
    catalogAccentValues[_stableHash(seed) % catalogAccentValues.length];

int _stableHash(String value) {
  var hash = 0;
  for (final codeUnit in value.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0x7fffffff;
  }
  return hash;
}

Duration durationFrom(Object? value) {
  if (value is num) {
    return Duration(seconds: value.round());
  }

  final raw = stringValue(value);
  final colonIndex = raw.lastIndexOf(':');
  if (colonIndex > 0) {
    final minutes = int.tryParse(raw.substring(0, colonIndex));
    final seconds = int.tryParse(raw.substring(colonIndex + 1));
    if (minutes != null && seconds != null) {
      return Duration(minutes: minutes, seconds: seconds);
    }
  }

  final seconds = int.tryParse(raw);
  return seconds == null ? Duration.zero : Duration(seconds: seconds);
}

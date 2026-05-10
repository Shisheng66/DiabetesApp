/// Safely convert a dynamic value to double.
double? toDouble(dynamic value) {
  final parsed = value is num ? value.toDouble() : double.tryParse('$value');
  if (parsed == null || !parsed.isFinite) return null;
  return parsed;
}

/// Safely convert a dynamic value to int.
int? toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

/// Safely cast a dynamic value to Map<String, dynamic>.
Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((k, v) => MapEntry('$k', v));
  return const <String, dynamic>{};
}

/// Safely cast a dynamic value to List.
List<dynamic> asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

/// Extract a list from common API response patterns (content, data, items, or nested).
List<dynamic> extractList(dynamic json) {
  if (json is List) return json;
  if (json is Map) {
    if (json['content'] is List) return json['content'] as List;
    if (json['data'] is List) return json['data'] as List;
    if (json['items'] is List) return json['items'] as List;
    if (json['data'] is Map && (json['data'] as Map)['content'] is List) {
      return (json['data'] as Map)['content'] as List;
    }
  }
  return const [];
}

/// Read an int from a dynamic value (e.g. JSON map entry).
int? readInt(dynamic value) => toInt(value);

/// Check if a phone number string is valid (Chinese mobile format).
bool isPhoneValid(String phone) => RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);

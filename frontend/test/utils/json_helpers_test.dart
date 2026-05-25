import 'package:flutter_test/flutter_test.dart';
import 'package:diabetes_health/utils/json_helpers.dart';

void main() {
  group('toDouble', () {
    test('converts int to double', () {
      expect(toDouble(42), 42.0);
    });
    test('converts double', () {
      expect(toDouble(3.14), 3.14);
    });
    test('converts string to double', () {
      expect(toDouble('2.5'), 2.5);
    });
    test('returns null for invalid string', () {
      expect(toDouble('abc'), isNull);
    });
    test('returns null for infinity', () {
      expect(toDouble(double.infinity), isNull);
    });
    test('returns null for null', () {
      expect(toDouble(null), isNull);
    });
  });

  group('toInt', () {
    test('converts int', () {
      expect(toInt(42), 42);
    });
    test('converts double to int', () {
      expect(toInt(3.14), 3);
    });
    test('converts string', () {
      expect(toInt('7'), 7);
    });
    test('returns null for invalid', () {
      expect(toInt('abc'), isNull);
    });
  });

  group('asMap', () {
    test('returns Map<String, dynamic> directly', () {
      final map = <String, dynamic>{'a': 1};
      expect(asMap(map), same(map));
    });
    test('converts Map<dynamic, dynamic>', () {
      final map = <dynamic, dynamic>{1: 'a', 'b': 2};
      final result = asMap(map);
      expect(result['1'], 'a');
      expect(result['b'], 2);
    });
    test('returns empty map for non-map', () {
      expect(asMap('not a map'), isEmpty);
    });
  });

  group('extractList', () {
    test('extracts from List directly', () {
      expect(extractList([1, 2, 3]), [1, 2, 3]);
    });
    test('extracts from content key', () {
      expect(extractList({'content': [1, 2]}), [1, 2]);
    });
    test('extracts from data key', () {
      expect(extractList({'data': [3, 4]}), [3, 4]);
    });
    test('extracts from items key', () {
      expect(extractList({'items': [5, 6]}), [5, 6]);
    });
    test('extracts from nested data.content', () {
      expect(extractList({'data': {'content': [7, 8]}}), [7, 8]);
    });
    test('returns empty list for unrecognized', () {
      expect(extractList({'unknown': 'value'}), isEmpty);
    });
  });

  group('isPhoneValid', () {
    test('validates correct phone', () {
      expect(isPhoneValid('13800138000'), isTrue);
    });
    test('rejects short phone', () {
      expect(isPhoneValid('138'), isFalse);
    });
    test('rejects invalid prefix', () {
      expect(isPhoneValid('23800138000'), isFalse);
    });
  });
}

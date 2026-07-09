import 'package:episodes_tracker/data/resilient_fetch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fetchOrNull', () {
    test('returns the value when the fetch succeeds', () async {
      final result = await fetchOrNull(() async => 42);
      expect(result, 42);
    });

    test('returns null instead of throwing when the fetch fails', () async {
      final result = await fetchOrNull<int>(
        () async => throw Exception('boom'),
      );
      expect(result, isNull);
    });

    test('Future.wait over mixed success/failure keeps the successes', () async {
      final results = await Future.wait([
        fetchOrNull(() async => 1),
        fetchOrNull<int>(() async => throw Exception('boom')),
        fetchOrNull(() async => 3),
      ]);
      expect(results.whereType<int>().toList(), [1, 3]);
    });
  });
}

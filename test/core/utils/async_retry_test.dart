import 'package:brixel/core/utils/async_retry.dart';
import 'package:flutter_test/flutter_test.dart';

class TemporaryFailure implements Exception {}

class PermanentFailure implements Exception {}

void main() {
  group('runWithRetry', () {
    test('returns immediately when the first attempt succeeds', () async {
      var attempts = 0;
      var delays = 0;

      final result = await runWithRetry<String>(
        operation: () async {
          attempts++;
          return 'success';
        },
        shouldRetry: (error) => error is TemporaryFailure,
        delay: (_) async {
          delays++;
        },
      );

      expect(result, 'success');
      expect(attempts, 1);
      expect(delays, 0);
    });

    test('retries a temporary failure and then succeeds', () async {
      var attempts = 0;
      var delays = 0;

      final result = await runWithRetry<String>(
        operation: () async {
          attempts++;

          if (attempts < 3) {
            throw TemporaryFailure();
          }

          return 'success';
        },
        shouldRetry: (error) => error is TemporaryFailure,
        maxAttempts: 3,
        delay: (_) async {
          delays++;
        },
      );

      expect(result, 'success');

      // Attempt 1 failed.
      // Attempt 2 failed.
      // Attempt 3 succeeded.
      expect(attempts, 3);

      // We wait only between failed attempts.
      expect(delays, 2);
    });

    test('does not retry a permanent failure', () async {
      var attempts = 0;
      var delays = 0;

      await expectLater(
        runWithRetry<void>(
          operation: () async {
            attempts++;
            throw PermanentFailure();
          },
          shouldRetry: (error) => error is TemporaryFailure,
          maxAttempts: 3,
          delay: (_) async {
            delays++;
          },
        ),
        throwsA(isA<PermanentFailure>()),
      );

      expect(attempts, 1);
      expect(delays, 0);
    });

    test('stops after the maximum number of attempts', () async {
      var attempts = 0;
      var delays = 0;

      await expectLater(
        runWithRetry<void>(
          operation: () async {
            attempts++;
            throw TemporaryFailure();
          },
          shouldRetry: (error) => error is TemporaryFailure,
          maxAttempts: 3,
          delay: (_) async {
            delays++;
          },
        ),
        throwsA(isA<TemporaryFailure>()),
      );

      expect(attempts, 3);
      expect(delays, 2);
    });

    test('rejects a maximum attempt count below one', () async {
      var attempts = 0;

      await expectLater(
        runWithRetry<void>(
          operation: () async {
            attempts++;
          },
          shouldRetry: (_) => true,
          maxAttempts: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(attempts, 0);
    });
  });
}

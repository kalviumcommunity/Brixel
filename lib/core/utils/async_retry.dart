typedef AsyncOperation<T> = Future<T> Function();

typedef RetryPredicate = bool Function(Object error);

typedef DelayFunction = Future<void> Function(Duration duration);

Future<T> runWithRetry<T>({
  required AsyncOperation<T> operation,
  required RetryPredicate shouldRetry,
  int maxAttempts = 3,
  Duration retryDelay = const Duration(milliseconds: 200),
  DelayFunction delay = _defaultDelay,
}) async {
  if (maxAttempts < 1) {
    throw ArgumentError.value(maxAttempts, 'maxAttempts', 'must be at least 1');
  }

  var attempt = 0;

  while (true) {
    attempt++;

    try {
      return await operation();
    } catch (error) {
      final canRetry = attempt < maxAttempts && shouldRetry(error);

      if (!canRetry) {
        rethrow;
      }

      await delay(retryDelay);
    }
  }
}

Future<void> _defaultDelay(Duration duration) {
  return Future<void>.delayed(duration);
}

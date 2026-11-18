/// The outcome of an operation that can fail in an expected way.
///
/// Services and repositories return a [Result] instead of throwing, so the
/// caller has to handle both cases: a `switch` on the sealed type is
/// exhaustive. Programming errors still throw.
sealed class Result<T> {
  const Result();

  /// A successful result carrying [value].
  const factory Result.ok(T value) = Ok<T>;

  /// A failed result carrying [error].
  const factory Result.error(Exception error) = Error<T>;
}

/// A successful [Result].
final class Ok<T> extends Result<T> {
  /// Creates a successful result with [value].
  const Ok(this.value);

  /// The value of the successful operation.
  final T value;

  @override
  String toString() => 'Result<$T>.ok($value)';
}

/// A failed [Result].
final class Error<T> extends Result<T> {
  /// Creates a failed result with [error].
  const Error(this.error);

  /// The expected failure, for example a network or validation error.
  final Exception error;

  @override
  String toString() => 'Result<$T>.error($error)';
}

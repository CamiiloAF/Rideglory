class Failure implements Exception {
  Failure([final String? message]) : message = message ?? 'Unexpected error';

  final String message;

  @override
  String toString() => message;
}

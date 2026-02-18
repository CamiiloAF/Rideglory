class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException({required this.message, this.code});

  @override
  String toString() => message;
}

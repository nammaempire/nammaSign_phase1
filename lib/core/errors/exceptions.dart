/// Internal exceptions thrown by data sources.
/// Repositories catch these and convert to [Failure] objects.
library;

class ServerException implements Exception {
  const ServerException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => message;
}

class CacheException implements Exception {
  const CacheException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  const NetworkException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthException implements Exception {
  const AuthException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => message;
}

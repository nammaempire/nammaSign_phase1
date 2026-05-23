/// Sealed failure type returned from repositories.
///
/// Use this instead of throwing raw exceptions out of the data layer.
sealed class Failure {
  const Failure(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => '$runtimeType($code): $message';
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code});
}

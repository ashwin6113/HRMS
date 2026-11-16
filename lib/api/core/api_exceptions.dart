class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([super.message = 'No internet connection available.'])
      : super(statusCode: 0);
}

class TimeoutException extends ApiException {
  const TimeoutException([super.message = 'The server took too long to respond.'])
      : super(statusCode: 408);
}

class ConflictException extends ApiException {
  const ConflictException(super.message, {super.details})
      : super(statusCode: 409);
}

class ValidationException extends ApiException {
  const ValidationException(super.message, {super.details})
      : super(statusCode: 422);
}

class ServerException extends ApiException {
  const ServerException([super.message = 'An internal server error occurred.'])
      : super(statusCode: 500);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Unauthorized access.'])
      : super(statusCode: 401);
}

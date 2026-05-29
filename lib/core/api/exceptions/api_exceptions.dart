abstract class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class NoInternetException extends ApiException {
  NoInternetException() : super('No internet connection available.');
}

class SongUnavailableException extends ApiException {
  SongUnavailableException(super.message);
}

class RateLimitException extends ApiException {
  RateLimitException() : super('Request limit reached. Please try again later.');
}

class ParseException extends ApiException {
  ParseException(super.message);
}

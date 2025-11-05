class OutboxException implements Exception {
  final String message;
  OutboxException(this.message);

  @override
  String toString() => 'OutboxException: $message';
}

class OutboxUnauthorizedException implements OutboxException {
  @override
  final String message;
  OutboxUnauthorizedException(this.message);

  @override
  String toString() => 'OutboxException: $message';
}

class OutboxDependencyFailureException implements OutboxException {
  @override
  final String message;
  OutboxDependencyFailureException(this.message);

  @override
  String toString() => 'OutboxException: $message';
}

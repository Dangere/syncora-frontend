import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';

/// Exceptions thrown by the outbox
class OutboxException implements Exception {
  final String message;
  OutboxException(this.message);

  @override
  String toString() => 'OutboxException: $message';
}

/// Outbox Exception the entry fails due to unauthorized
class OutboxUnauthorizedException implements OutboxException {
  @override
  final String message;
  OutboxUnauthorizedException(this.message);

  @override
  String toString() => 'OutboxException: $message';
}

/// Outbox Exception the entry fails due to dependency
/// i.e task entity depending on a group to exist but got deleted
class OutboxDependencyFailureException implements OutboxException {
  @override
  final String message;
  OutboxDependencyFailureException(this.message);

  @override
  String toString() => 'OutboxException: $message';
}

/// Outbox Exception the entry fails due to no processor
/// Such as a group entity not having a group processor
class OutboxNoProcessorException implements OutboxException {
  final OutboxEntityType type;
  OutboxNoProcessorException(this.type);

  @override
  String toString() =>
      "OutboxException: could't find processor for ${type.name}";

  @override
  // TODO: implement message
  String get message => toString();
}

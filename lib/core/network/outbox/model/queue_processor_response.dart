import 'dart:collection';

class QueueProcessorResponse {
  final HashSet<int> modifiedGroupIds;
  final List<Exception> errors;

  QueueProcessorResponse(this.modifiedGroupIds, this.errors);
}

import 'dart:collection';

import 'package:syncora_frontend/core/utils/app_error.dart';

class QueueProcessorResponse {
  final HashSet<int> modifiedGroupIds;
  final List<AppError> errors;

  QueueProcessorResponse(this.modifiedGroupIds, this.errors);
}

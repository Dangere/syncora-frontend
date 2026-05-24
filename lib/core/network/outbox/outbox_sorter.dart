import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';

/// Class used to sort the outbox queue into creation order
class OutboxSorter {
  /// Priority: Create group -> modify group -> create task -> modify task -> rest of the queue
  static List<OutboxEntry> sort(List<OutboxEntry> entries) {
    entries.sort((a, b) {
      // If both are groups, creation comes first
      if (a.entityType == OutboxEntityType.group &&
          b.entityType == OutboxEntityType.group) {
        return a.actionType.index.compareTo(b.actionType.index);
      }

      // If both are tasks, creation comes first
      if (a.entityType == OutboxEntityType.task &&
          b.entityType == OutboxEntityType.task) {
        return a.actionType.index.compareTo(b.actionType.index);
      }

      return a.entityType.index.compareTo(b.entityType.index);
    });
    return entries;
  }
}

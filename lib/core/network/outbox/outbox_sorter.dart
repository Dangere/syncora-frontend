import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';

class OutboxSorter {
  /// Priority, Create group -> modify group -> create task -> modify task
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

      // // Both are creation, the group creation comes first then the task creation
      // if (a.actionType == OutboxActionType.create &&
      //     b.actionType == OutboxActionType.create) {
      //   return a.entityType.index.compareTo(b.entityType.index);
      // }
      // If the first is a group and the second is a task, group comes first
      // if (a.entityType == OutboxEntityType.group &&
      //     b.entityType == OutboxEntityType.task) {
      //   return -1;
      // }

      return a.entityType.index.compareTo(b.entityType.index);
    });
    return entries;
  }
}

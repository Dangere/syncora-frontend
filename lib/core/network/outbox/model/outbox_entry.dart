import 'dart:convert';
import 'package:syncora_frontend/core/network/outbox/model/outbox_payload.dart';

/// Represents an entry in the outbox queue
/// Each entry has an id, an entity id, an entity type, an action type, a status, and a creation date
/// An entry can have a payload, a dependency id, and a dependency type
/// An entry can be in the "pending" state, "in process" state, or "complete" state
class OutboxEntry {
  final int? id;
  final int entityId;
  // Whether the entry requires an authenticated user
  final bool requiresAuthentication;
  final OutboxEntityType entityType;
  final OutboxActionType actionType;
  final OutboxPayload? payload;
  // Entires that depend on a dependency will have a dependencyId, such as tasks that depend on a groupId
  final int? dependencyId;

  final OutboxStatus status;

  final DateTime creationDate;

  OutboxEntry(
      {this.id,
      required this.entityId,
      required this.entityType,
      required this.actionType,
      this.payload,
      required this.status,
      required this.creationDate,
      this.dependencyId,
      required this.requiresAuthentication});

  Map<String, dynamic> toTable() => {
        "entityId": entityId,
        "entityType": entityType.index,
        "actionType": actionType.index,
        "status": status.index,
        "creationDate": creationDate.toIso8601String(),
        "requiresAuthentication": requiresAuthentication ? 1 : 0,
        if (payload != null) "payload": jsonEncode(payload!.toJson()),
        if (dependencyId != null) "dependencyId": dependencyId,
      };

  /// Converts a map from the database to an [OutboxEntry] and deserializes the payload depending on the [entityType] and [actionType]
  factory OutboxEntry.fromTable(Map<String, dynamic> data) {
    OutboxEntityType entity =
        OutboxEntityType.values[data["entityType"] as int];
    OutboxActionType action =
        OutboxActionType.values[data["actionType"] as int];

    OutboxPayload? payload = data["payload"] == null
        ? null
        : deserializePayload(
            jsonDecode(data["payload"] as String),
            entity,
            action,
          );

    return OutboxEntry(
        id: data["id"],
        entityId: data["entityId"],
        entityType: entity,
        actionType: action,
        payload: payload,
        dependencyId: data["dependencyId"],
        status: OutboxStatus.values[data["status"] as int],
        creationDate: DateTime.parse(data["creationDate"]),
        requiresAuthentication: data["requiresAuthentication"] == 1);
  }

  factory OutboxEntry.entry({
    required int entityId,
    required OutboxEntityType entityType,
    required OutboxActionType actionType,
    bool requiresAuthentication = true,
    OutboxPayload? payload,
    int? dependencyId,
  }) {
    // Making sure we have a dependencyId that references a group for tasks
    if (entityType == OutboxEntityType.task) {
      assert(dependencyId != null);
    }
    return OutboxEntry(
        requiresAuthentication: requiresAuthentication,
        entityId: entityId,
        entityType: entityType,
        actionType: actionType,
        payload: payload,
        status: OutboxStatus.pending,
        dependencyId: dependencyId,
        creationDate: DateTime.now().toUtc());
  }

  /// Deserializes the payload depending on the [entityType] and [actionType]
  static OutboxPayload? deserializePayload(
    Map<String, dynamic> payloadMap,
    OutboxEntityType entityType,
    OutboxActionType actionType,
  ) {
    switch (entityType) {
      case OutboxEntityType.group:
        switch (actionType) {
          case OutboxActionType.update:
            return UpdateGroupPayload.fromJson(payloadMap);
          case OutboxActionType.create:
            return CreateGroupPayload.fromJson(payloadMap);
          // ... handle other actions for 'group'
          default:
            return null;
        }
      case OutboxEntityType.task:
        switch (actionType) {
          case OutboxActionType.update:
            return UpdateTaskPayload.fromJson(payloadMap);
          case OutboxActionType.create:
            return CreateTaskPayload.fromJson(payloadMap);
          case OutboxActionType.mark:
            return MarkTaskPayload.fromJson(payloadMap);
          // ... handle other actions for 'task'
          default:
            return null;
        }

      case OutboxEntityType.user:
        switch (actionType) {
          case OutboxActionType.update:
            return UpdateUserPreferencesPayload.fromJson(payloadMap);
          default:
            return null;
        }
      // Report payloads are null and only carry the id in the entity id
      case OutboxEntityType.report:
        throw UnimplementedError();
    }
  }

  @override
  toString() =>
      'entity: ${entityType.name}, action: ${actionType.name}, payload: ${payload?.toJson()}, status: ${status.name}, id: $id';
}

enum OutboxStatus { pending, complete, inProcess, failed, ignored }

enum OutboxEntityType { group, task, user, report }

enum OutboxActionType { create, delete, update, mark, leave }

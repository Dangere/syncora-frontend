import 'dart:convert';
import 'package:syncora_frontend/core/network/outbox/model/outbox_payload.dart';

class OutboxEntry {
  final int? id;
  final int entityId;
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
      this.dependencyId});

  Map<String, dynamic> toTable() => {
        "entityId": entityId,
        "entityType": entityType.index,
        "actionType": actionType.index,
        "status": status.index,
        "creationDate": creationDate.toIso8601String(),
        if (payload != null) "payload": jsonEncode(payload!.toJson()),
        if (dependencyId != null) "dependencyId": dependencyId,
      };

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
        creationDate: DateTime.parse(data["creationDate"]));
  }

  factory OutboxEntry.entry(
      {required int entityId,
      required OutboxEntityType entityType,
      required OutboxActionType actionType,
      OutboxPayload? payload,
      int? dependencyId}) {
    // Making sure we have a dependencyId that references a group for tasks
    if (entityType == OutboxEntityType.task) {
      assert(dependencyId != null);
    }
    return OutboxEntry(
        entityId: entityId,
        entityType: entityType,
        actionType: actionType,
        payload: payload,
        status: OutboxStatus.pending,
        dependencyId: dependencyId,
        creationDate: DateTime.now().toUtc());
  }

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
      default:
        return null;
    }
  }

  @override
  toString() =>
      'entity: ${entityType.name}, action: ${actionType.name}, payload: $payload, status: ${status.name}, id: $id';
}

enum OutboxStatus { pending, complete, inProcess, failed, ignored }

enum OutboxEntityType { group, task }

enum OutboxActionType { create, delete, update, mark, leave }

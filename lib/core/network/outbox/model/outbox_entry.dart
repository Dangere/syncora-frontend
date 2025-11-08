import 'dart:convert';
import 'package:syncora_frontend/core/network/outbox/model/outbox_payload.dart';

class OutboxEntry {
  final int? id;
  final int entityId;
  final OutboxEntityType entityType;
  final OutboxActionType actionType;
  final OutboxPayload? payload;
  final OutboxStatus status;

  final DateTime creationDate;

  OutboxEntry(
      {this.id,
      required this.entityId,
      required this.entityType,
      required this.actionType,
      this.payload,
      required this.status,
      required this.creationDate});

  Map<String, dynamic> toTable() => {
        "entityId": entityId,
        "entityType": entityType.index,
        "actionType": actionType.index,
        if (payload != null) "payload": jsonEncode(payload!.toJson()),
        "status": status.index,
        "creationDate": creationDate.toIso8601String(),
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
        status: OutboxStatus.values[data["status"] as int],
        creationDate: DateTime.parse(data["creationDate"]));
  }

  factory OutboxEntry.entry(
      {required int entityId,
      required OutboxEntityType entityType,
      required OutboxActionType actionType,
      OutboxPayload? payload}) {
    return OutboxEntry(
        entityId: entityId,
        entityType: entityType,
        actionType: actionType,
        payload: payload,
        status: OutboxStatus.pending,
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
            return OutboxTaskPayload.fromJson(payloadMap);
        }
      default:
        return null;
    }
  }

  @override
  toString() =>
      'OutboxEntry(id: $id, entityId: $entityId, entityType: $entityType, actionType: $actionType, payload: $payload, status: $status, creationDate: $creationDate)';
}

enum OutboxStatus { pending, complete, inProcess, failed }

enum OutboxEntityType { group, task }

enum OutboxActionType { create, delete, update, mark, leave }

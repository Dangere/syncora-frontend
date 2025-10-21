import 'dart:convert';

class OutboxEntry {
  final int? id;
  final int entityId;
  final OutboxEntityType entityType;
  final OutboxActionType actionType;
  final Map<String, dynamic> payload;
  final OutboxStatus status;

  final DateTime creationDate;

  OutboxEntry(
      {this.id,
      required this.entityId,
      required this.entityType,
      required this.actionType,
      required this.payload,
      required this.status,
      required this.creationDate});

  Map<String, dynamic> toTable() => {
        "entityId": entityId,
        "entityType": entityType.index,
        "actionType": actionType.index,
        "payload": jsonEncode(payload),
        "status": status.index,
        "creationDate": creationDate.toIso8601String(),
      };

  factory OutboxEntry.fromTable(Map<String, dynamic> data) {
    return OutboxEntry(
        id: data["id"],
        entityId: data["entityId"],
        entityType: OutboxEntityType.values[data["entityType"] as int],
        actionType: OutboxActionType.values[data["actionType"] as int],
        payload: jsonDecode(data["payload"]),
        status: OutboxStatus.values[data["status"] as int],
        creationDate: DateTime.parse(data["creationDate"]));
  }

  factory OutboxEntry.entry(
      {required int entityId,
      required OutboxEntityType entityType,
      required OutboxActionType actionType,
      required Map<String, dynamic> payload}) {
    return OutboxEntry(
        entityId: entityId,
        entityType: entityType,
        actionType: actionType,
        payload: payload,
        status: OutboxStatus.pending,
        creationDate: DateTime.now().toUtc());
  }

  @override
  toString() =>
      'OutboxEntry(id: $id, entityId: $entityId, entityType: $entityType, actionType: $actionType, payload: $payload, status: $status, creationDate: $creationDate)';
}

enum OutboxStatus { pending, complete, inProcess, failed }

enum OutboxEntityType { group, task }

enum OutboxActionType { create, delete, update, mark, leave }

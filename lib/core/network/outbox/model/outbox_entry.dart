import 'dart:convert';

class OutboxEntry {
  final int? id;
  final int entityTempId;
  final OutboxEntityType entityType;
  final OutBoxActionType actionType;
  final Map<String, dynamic> payload;
  final OutboxStatus status;

  final DateTime creationDate;

  OutboxEntry(
      {this.id,
      required this.entityTempId,
      required this.entityType,
      required this.actionType,
      required this.payload,
      required this.status,
      required this.creationDate});

  Map<String, dynamic> toTable() => {
        "entityTempId": entityTempId,
        "entityType": entityType.index,
        "actionType": actionType.index,
        "payload": jsonEncode(payload),
        "status": status.index,
        "creationDate": creationDate.toIso8601String(),
      };

  factory OutboxEntry.fromTable(Map<String, dynamic> data) {
    return OutboxEntry(
        id: data["id"],
        entityTempId: data["entityTempId"],
        entityType: OutboxEntityType.values[data["entityType"] as int],
        actionType: OutBoxActionType.values[data["actionType"] as int],
        payload: jsonDecode(data["payload"]),
        status: OutboxStatus.values[data["status"] as int],
        creationDate: DateTime.parse(data["creationDate"]));
  }

  factory OutboxEntry.entry(
      {required entityTempId,
      required entityType,
      required actionType,
      required payload}) {
    return OutboxEntry(
        entityTempId: entityTempId,
        entityType: entityType,
        actionType: actionType,
        payload: payload,
        status: OutboxStatus.pending,
        creationDate: DateTime.now().toUtc());
  }
}

enum OutboxStatus { pending, complete, inProcess, failed }

enum OutboxEntityType { task, group }

enum OutBoxActionType { create, delete, update, mark }

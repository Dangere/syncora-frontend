import 'dart:convert';

import 'package:syncora_frontend/features/groups/models/group_dto.dart';
import 'package:equatable/equatable.dart';

class Group extends Equatable {
  final int id;
  final String title;
  final String? description;
  final DateTime creationDate;
  final int ownerUserId;
  final List<int> groupMembersIds;
  final List<int> tasksIds;
  const Group({
    required this.id,
    required this.title,
    this.description,
    required this.creationDate,
    required this.ownerUserId,
    required this.groupMembersIds,
    required this.tasksIds,
  });

  factory Group.fromDto(GroupDTO dto, List<int> taskIds) {
    return Group(
      id: dto.id,
      title: dto.title,
      description: dto.description,
      creationDate: dto.creationDate,
      ownerUserId: dto.ownerUserId,
      groupMembersIds: dto.groupMembers,
      tasksIds: taskIds,
    );
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    final List<int> members = json['members'] == null
        ? const []
        : List<int>.from(jsonDecode(json['members'] as String));
    final List<int> tasks = json['tasks'] == null
        ? const []
        : List<int>.from(jsonDecode(json['members'] as String));
    return Group(
        id: json["id"],
        title: json["title"],
        description: json["description"],
        creationDate: DateTime.parse(json["creationDate"]),
        ownerUserId: json["ownerUserId"],
        groupMembersIds: members,
        tasksIds: tasks);
  }

  Map<String, dynamic> toTable() => {
        "id": id,
        "title": title,
        "description": description,
        "creationDate": creationDate.toIso8601String(),
        "ownerUserId": ownerUserId,
      };

  Group copyWith(
          {int? id,
          String? title,
          String? description,
          List<int>? groupMembersIds,
          List<int>? tasksIds}) =>
      Group(
          id: id ?? this.id,
          title: title ?? this.title,
          description: description ?? this.description,
          creationDate: creationDate,
          ownerUserId: ownerUserId,
          groupMembersIds: groupMembersIds ?? this.groupMembersIds,
          tasksIds: tasksIds ?? this.tasksIds);

  // Equatable will use these properties to check for equality.
  @override
  List<Object?> get props => [
        id,
        title,
        description,
        creationDate,
        ownerUserId,
        groupMembersIds,
        tasksIds,
      ];
}

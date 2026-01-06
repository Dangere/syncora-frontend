import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/groups/models/group_dto.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';
import 'dart:convert';

class SyncPayload {
  final String timestamp;
  final List<GroupDTO> groups;
  final List<Task> tasks;
  final List<User> users;

  final List<int> deletedGroups;
  final List<int> deletedTasks;
  final List<int> kickedGroupsIds;

  SyncPayload(
      {required this.timestamp,
      required this.groups,
      required this.tasks,
      required this.users,
      required this.deletedGroups,
      required this.deletedTasks,
      required this.kickedGroupsIds});

  factory SyncPayload.fromJson(Map<String, dynamic> json) => SyncPayload(
      timestamp: json['timestamp'],
      groups:
          List<GroupDTO>.from(json['groups'].map((x) => GroupDTO.fromJson(x))),
      tasks: List<Task>.from(json['tasks'].map((x) => Task.fromJson(x))),
      users: List<User>.from(json['users'].map((x) => User.fromJson(x))),
      deletedGroups: List<int>.from(json['deletedGroupsIds']),
      deletedTasks: List<int>.from(json['deletedTasksIds']),
      kickedGroupsIds: List<int>.from(json['kickedGroupsIds']));

  HashSet<int> groupIds() {
    HashSet<int> ids = HashSet<int>();
    for (var element in groups) {
      ids.add(element.id);
    }

    for (var element in tasks) {
      ids.add(element.groupId);
    }

    for (var element in kickedGroupsIds) {
      ids.add(element);
    }

    return ids;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'timestamp': timestamp,
        'groups': groups.map((x) => x.toJson()).toList(),
        'tasks': tasks.map((x) => x.toJson()).toList(),
        'users': users.map((x) => x.toJson()).toList(),
        'deletedGroups': deletedGroups.toList(),
        'deletedTasks': deletedTasks.toList(),
        'kickedGroupsIds': kickedGroupsIds.toList()
      };

  bool isEmpty() =>
      groups.isEmpty &&
      tasks.isEmpty &&
      users.isEmpty &&
      deletedGroups.isEmpty &&
      deletedTasks.isEmpty &&
      kickedGroupsIds.isEmpty;
  @override
  String toString() {
    JsonEncoder encoder =
        const JsonEncoder.withIndent('  '); // Use 2 spaces for indentation
    String prettyJson = encoder.convert(toJson());
    return prettyJson;
  }
}

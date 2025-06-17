import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';

class SyncPayload {
  final String timestamp;
  final List<Group> groups;
  final List<Task> tasks;
  final List<User> users;

  final List<Group> deletedGroups;
  final List<Task> deletedTasks;

  SyncPayload(
      {required this.timestamp,
      required this.groups,
      required this.tasks,
      required this.users,
      required this.deletedGroups,
      required this.deletedTasks});

  factory SyncPayload.fromJson(Map<String, dynamic> json) => SyncPayload(
      timestamp: json['timestamp'],
      groups: List<Group>.from(json['groups'].map((x) => Group.fromJson(x))),
      tasks: List<Task>.from(json['tasks'].map((x) => Task.fromJson(x))),
      users: List<User>.from(json['users'].map((x) => User.fromJson(x))),
      deletedGroups:
          List<Group>.from(json['deletedGroups'].map((x) => Group.fromJson(x))),
      deletedTasks:
          List<Task>.from(json['deletedTasks'].map((x) => Task.fromJson(x))));
}

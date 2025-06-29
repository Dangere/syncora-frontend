import 'dart:ffi';

class Task {
  final int id;
  final String title;
  final String? description;
  final bool completed;
  final String? completedBy;
  final DateTime creationDate;
  final DateTime? lastModifiedDate;
  final int groupId;

  Task({
    required this.id,
    required this.title,
    required this.creationDate,
    required this.groupId,
    this.description,
    this.completed = false,
    this.completedBy,
    this.lastModifiedDate,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        groupId: json['groupId'],
        title: json['title'] as String,
        description: json['description'] as String?,
        completed: json['completed'] as bool,
        completedBy: json['CompletedById'] as String?,
        creationDate: DateTime.parse(json['creationDate'] as String),
        lastModifiedDate: json['LastModifiedDate'] != null
            ? DateTime.parse(json['lastUpdateDate'] as String)
            : null,
      );
}

class Task {
  final int id;
  final String title;
  final String? description;
  final bool completed;
  final int? completedById;
  final DateTime creationDate;
  // final DateTime? lastModifiedDate;
  final int groupId;

  Task({
    required this.id,
    required this.title,
    required this.creationDate,
    required this.groupId,
    this.description,
    this.completed = false,
    this.completedById,
    // this.lastModifiedDate,
  });
  // Note: the local sqflite db converts bool into int so we convert it back to bool
  // However the backend returns a bool directly so we don't need to convert
  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        groupId: json['groupId'],
        title: json['title'] as String,
        description: json['description'] as String?,
        completed: (json['completed'] is int)
            ? (json['completed'] == 1 ? true : false)
            : json['completed'],
        completedById: json['completedById'] as int?,
        creationDate: DateTime.parse(json['creationDate'] as String),
        // lastModifiedDate: json['lastModifiedDate'] != null
        //     ? DateTime.parse(json['lastModifiedDate'] as String)
        //     : null,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'groupId': groupId,
        'title': title,
        'description': description,
        'completed': completed ? 1 : 0,
        'CompletedById': completedById,
        'creationDate': creationDate.toIso8601String(),
        // 'lastModifiedDate': lastModifiedDate?.toIso8601String(),
      };
}

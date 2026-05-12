class Task {
  final int id;
  final String title;
  final String? description;
  final int? completedById;
  final DateTime creationDate;
  // final DateTime? lastModifiedDate;
  final int groupId;
  final List<int> assignedTo;

  Task({
    required this.id,
    required this.title,
    required this.creationDate,
    required this.groupId,
    required this.assignedTo,
    this.description,
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
        assignedTo: List<int>.from(json['assignedTo']),
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
        'assignedTo': assignedTo,
        'CompletedById': completedById,
        'creationDate': creationDate.toIso8601String(),
        // 'lastModifiedDate': lastModifiedDate?.toIso8601String(),
      };

  Map<String, dynamic> toTable() => {
        "id": id,
        "groupId": groupId,
        "title": title,
        "description": description,
        "completedById": completedById,
        "creationDate": creationDate.toIso8601String(),
        // "lastModifiedDate": lastModifiedDate?.toIso8601String(),
      };
}

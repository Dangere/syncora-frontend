class Task {
  final String id;
  final String title;
  final String? description;
  final bool isDone;
  final DateTime creationDate;
  final DateTime? lastUpdateDate;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.isDone = false,
    required this.creationDate,
    this.lastUpdateDate,
  });
}

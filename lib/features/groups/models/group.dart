class Group {
  final int id;
  final String title;
  final String? description;
  final DateTime creationDate;
  final int ownerId;
  final List<String> members;

  Group(
      {required this.id,
      required this.title,
      required this.description,
      required this.creationDate,
      required this.ownerId,
      required this.members});
}

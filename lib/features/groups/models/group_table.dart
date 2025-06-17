class GroupTable {
  final int? id;
  final int ownerId;
  final String title;
  final String description;
  final String creationDate;

  GroupTable(
      {this.id,
      required this.ownerId,
      required this.title,
      required this.description,
      required this.creationDate});
}

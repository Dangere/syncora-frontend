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

  factory Group.fromJson(Map<String, dynamic> json) => Group(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      creationDate: DateTime.parse(json['creationDate']),
      ownerId: json['ownerUserId'],
      members: List<String>.from(json['groupMembers']));

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "description": description,
        "creationDate": creationDate.toIso8601String(),
        "ownerUserId": ownerId,
        "members": members
      };
}

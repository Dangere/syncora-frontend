import 'package:logger/logger.dart';

class Group {
  final int id;
  final String title;
  final String? description;
  final DateTime creationDate;
  final int ownerUserId;
  final List<int> groupMembers;

  Group(
      {required this.id,
      required this.title,
      required this.description,
      required this.creationDate,
      required this.ownerUserId,
      required this.groupMembers});

  factory Group.fromJson(Map<String, dynamic> json) => Group(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      creationDate: DateTime.parse(json['creationDate']),
      ownerUserId: json['ownerUserId'],
      groupMembers: List<int>.from(json['groupMembers']));

  factory Group.fromJsonWithMembers(
      Map<String, dynamic> json, List<Map<String, dynamic>> groupMembers) {
    return Group(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        creationDate: DateTime.parse(json['creationDate']),
        ownerUserId: json['ownerUserId'],
        groupMembers:
            // Currently only storing username of members in group
            groupMembers.map((e) => e["id"] as int).toList());
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "description": description,
        "creationDate": creationDate.toIso8601String(),
        "ownerUserId": ownerUserId,
        "groupMembers": groupMembers
      };

  Map<String, dynamic> toTable() => {
        "id": id,
        "title": title,
        "description": description,
        "creationDate": creationDate.toIso8601String(),
        "ownerUserId": ownerUserId,
      };
}

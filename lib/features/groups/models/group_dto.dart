class GroupDTO {
  final int id;
  final String title;
  final String? description;
  final DateTime creationDate;
  final int ownerUserId;
  final List<int> groupMembersIds;

  GroupDTO(
      {required this.id,
      required this.title,
      required this.description,
      required this.creationDate,
      required this.ownerUserId,
      required this.groupMembersIds});

  factory GroupDTO.fromJson(Map<String, dynamic> json) => GroupDTO(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      creationDate: DateTime.parse(json['creationDate']),
      ownerUserId: json['ownerUserId'],
      groupMembersIds: List<int>.from(json['groupMembers']));

  factory GroupDTO.fromJsonWithMembers(
      Map<String, dynamic> json, List<Map<String, dynamic>> groupMembers) {
    return GroupDTO(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        creationDate: DateTime.parse(json['creationDate']),
        ownerUserId: json['ownerUserId'],
        groupMembersIds:
            // Currently only storing id of members in group
            groupMembers.map((e) => e["id"] as int).toList());
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "description": description,
        "creationDate": creationDate.toIso8601String(),
        "ownerUserId": ownerUserId,
        "groupMembers": groupMembersIds
      };

  Map<String, dynamic> toTable() => {
        "id": id,
        "title": title,
        "description": description,
        "creationDate": creationDate.toIso8601String(),
        "ownerUserId": ownerUserId,
      };
}

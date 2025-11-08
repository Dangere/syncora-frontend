sealed class OutboxPayload {
  Map<String, dynamic> toJson();
}

extension OutboxPayloadX on OutboxPayload {
  UpdateGroupPayload? get asUpdateGroupPayload =>
      this is UpdateGroupPayload ? this as UpdateGroupPayload : null;

  CreateGroupPayload? get asCreateGroupPayload =>
      this is CreateGroupPayload ? this as CreateGroupPayload : null;

  UpdateTaskPayload? get asUpdateTaskPayload =>
      this is UpdateTaskPayload ? this as UpdateTaskPayload : null;

  OutboxTaskPayload? get asOutboxTaskPayload =>
      this is OutboxTaskPayload ? this as OutboxTaskPayload : null;

  CreateTaskPayload? get asCreateTaskPayload =>
      this is CreateTaskPayload ? this as CreateTaskPayload : null;

  MarkTaskPayload? get asMarkTaskPayload =>
      this is MarkTaskPayload ? this as MarkTaskPayload : null;
}

class UpdateGroupPayload extends OutboxPayload {
  final String? title;
  final String? description;
  final String oldTitle;
  final String? oldDescription;
  UpdateGroupPayload(
      {this.title,
      this.description,
      required this.oldTitle,
      required this.oldDescription})
      : assert(title != null || description != null);
  @override
  Map<String, dynamic> toJson() {
    return {
      if (title != null) "title": title,
      if (description != null) "description": description,
      if (oldDescription != null) "oldDescription": oldDescription,
      "oldTitle": oldTitle
    };
  }

  factory UpdateGroupPayload.fromJson(Map<String, dynamic> json) =>
      UpdateGroupPayload(
          title: json["title"],
          description: json["description"],
          oldTitle: json["oldTitle"],
          oldDescription: json["oldDescription"]);

  void refreshOldData() {}
}

class CreateGroupPayload extends OutboxPayload {
  final String title;
  final String? description;

  CreateGroupPayload({required this.title, this.description});
  @override
  Map<String, dynamic> toJson() {
    return {
      "title": title,
      if (description != null) "description": description,
    };
  }

  factory CreateGroupPayload.fromJson(Map<String, dynamic> json) =>
      CreateGroupPayload(
        title: json["title"],
        description: json["description"],
      );
}

class OutboxTaskPayload extends OutboxPayload {
  final int groupId;

  OutboxTaskPayload({required this.groupId});

  @override
  Map<String, dynamic> toJson() {
    return {
      "groupId": groupId,
    };
  }

  factory OutboxTaskPayload.fromJson(Map<String, dynamic> json) =>
      OutboxTaskPayload(groupId: json["groupId"]);
}

class UpdateTaskPayload extends OutboxTaskPayload {
  final String? title;
  final String? description;
  final String oldTitle;
  final String? oldDescription;
  UpdateTaskPayload({
    required super.groupId,
    this.title,
    this.description,
    required this.oldTitle,
    required this.oldDescription,
  }) : assert(title != null || description != null);
  @override
  Map<String, dynamic> toJson() {
    var map = super.toJson();
    map.addAll({
      if (title != null) "title": title,
      if (description != null) "description": description,
      "oldTitle": oldTitle,
      if (oldDescription != null) "oldDescription": oldDescription
    });
    return map;
  }

  factory UpdateTaskPayload.fromJson(Map<String, dynamic> json) =>
      UpdateTaskPayload(
          groupId: json["groupId"],
          title: json["title"],
          description: json["description"],
          oldTitle: json["oldTitle"],
          oldDescription: json["oldDescription"]);
}

class CreateTaskPayload extends OutboxTaskPayload {
  final String title;
  final String? description;

  CreateTaskPayload(
      {required super.groupId, required this.title, required this.description});
  @override
  Map<String, dynamic> toJson() {
    var map = super.toJson();
    map.addAll(
        {"title": title, if (description != null) "description": description});
    return map;
  }

  factory CreateTaskPayload.fromJson(Map<String, dynamic> json) =>
      CreateTaskPayload(
          title: json["title"],
          description: json["description"],
          groupId: json["groupId"] as int);
}

class MarkTaskPayload extends OutboxTaskPayload {
  final int completedById;
  final bool isCompleted;

  MarkTaskPayload(
      {required super.groupId,
      required this.completedById,
      required this.isCompleted});
  @override
  Map<String, dynamic> toJson() {
    var map = super.toJson();
    map.addAll({"completedById": completedById, "isCompleted": isCompleted});
    return map;
  }

  factory MarkTaskPayload.fromJson(Map<String, dynamic> json) =>
      MarkTaskPayload(
          completedById: json["completedById"],
          isCompleted: json["isCompleted"],
          groupId: json["groupId"] as int);
}

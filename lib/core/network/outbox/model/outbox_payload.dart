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

class UpdateTaskPayload extends OutboxPayload {
  final String? title;
  final String? description;
  final String oldTitle;
  final String? oldDescription;
  UpdateTaskPayload({
    this.title,
    this.description,
    required this.oldTitle,
    required this.oldDescription,
  }) : assert(title != null || description != null);
  @override
  Map<String, dynamic> toJson() {
    return {
      if (title != null) "title": title,
      if (description != null) "description": description,
      "oldTitle": oldTitle,
      if (oldDescription != null) "oldDescription": oldDescription
    };
  }

  factory UpdateTaskPayload.fromJson(Map<String, dynamic> json) =>
      UpdateTaskPayload(
          title: json["title"],
          description: json["description"],
          oldTitle: json["oldTitle"],
          oldDescription: json["oldDescription"]);
}

class CreateTaskPayload extends OutboxPayload {
  final String title;
  final String? description;

  CreateTaskPayload({required this.title, required this.description});
  @override
  Map<String, dynamic> toJson() {
    return {
      "title": title,
      if (description != null) "description": description
    };
  }

  factory CreateTaskPayload.fromJson(Map<String, dynamic> json) =>
      CreateTaskPayload(title: json["title"], description: json["description"]);
}

class MarkTaskPayload extends OutboxPayload {
  final int completedById;
  final bool isCompleted;

  MarkTaskPayload({required this.completedById, required this.isCompleted});
  @override
  Map<String, dynamic> toJson() {
    return {"completedById": completedById, "isCompleted": isCompleted};
  }

  factory MarkTaskPayload.fromJson(Map<String, dynamic> json) =>
      MarkTaskPayload(
          completedById: json["completedById"],
          isCompleted: json["isCompleted"]);
}

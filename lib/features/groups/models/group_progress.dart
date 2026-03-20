class GroupProgress {
  final int groupId;
  final String groupTitle;

  final int completedTasks;
  final int incompleteTasks;

  GroupProgress(
      {required this.groupId,
      required this.groupTitle,
      required this.completedTasks,
      required this.incompleteTasks});

  factory GroupProgress.fromJson(Map<String, dynamic> json) {
    return GroupProgress(
        groupId: json['groupId'],
        groupTitle: json['groupTitle'],
        completedTasks: json['completedTasks'],
        incompleteTasks: json['incompleteTasks']);
  }

  @override
  String toString() {
    return 'GroupProgress{groupId: $groupId, groupTitle: $groupTitle, completedTasks: $completedTasks, incompleteTasks: $incompleteTasks}';
  }
}

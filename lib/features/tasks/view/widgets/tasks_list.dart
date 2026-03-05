import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/filter_list.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';
import 'package:syncora_frontend/features/tasks/tasks_provider.dart';
import 'package:syncora_frontend/features/tasks/view/widgets/task_panel.dart';

// This will update itself when the group notifier updates
class TasksList extends ConsumerWidget {
  const TasksList({super.key, required this.groupId});

  final int groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<List<Task>> tasks = ref.watch(tasksProvider(groupId));

    bool isOwner = ref.read(tasksProvider(groupId).notifier).isOwner();
    ref.read(loggerProvider).d("TasksList: Building tasks list");

    Widget tasksList = Expanded(
      child: Column(
        children: [
          // FILTER
          FilterList<TaskFilter>(
              onTap: (arg) {
                ref.read(tasksProvider(groupId).notifier).filterTasks(arg);
              },
              multiSelect: true,
              disable: false,
              initialValue: ref.read(tasksProvider(groupId).notifier).filters,
              items: [
                FilterListItem(
                  title: AppLocalizations.of(context).filter_All,
                  value: TaskFilter.all,
                  opposites: [
                    TaskFilter.pending,
                    TaskFilter.completed,
                    TaskFilter.assigned
                  ],
                ),
                FilterListItem(
                  title: AppLocalizations.of(context).filter_Completed,
                  value: TaskFilter.completed,
                  opposites: [TaskFilter.all, TaskFilter.pending],
                ),
                FilterListItem(
                  title: AppLocalizations.of(context).filter_Pending,
                  value: TaskFilter.pending,
                  opposites: [TaskFilter.all, TaskFilter.completed],
                ),
                FilterListItem(
                  title: AppLocalizations.of(context).filter_Assigned,
                  value: TaskFilter.assigned,
                  opposites: [TaskFilter.all],
                ),
                FilterListItem(
                  title: AppLocalizations.of(context).filter_Newest,
                  value: TaskFilter.newest,
                  opposites: [TaskFilter.oldest],
                ),
                FilterListItem(
                  title: AppLocalizations.of(context).filter_Oldest,
                  value: TaskFilter.oldest,
                  opposites: [TaskFilter.newest],
                ),
              ]),
          const SizedBox(height: AppSpacing.md / 2),

          // TASKS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md / 2),
                itemCount: tasks.hasValue ? tasks.value!.length : 0,
                itemBuilder: (context, index) {
                  return TaskPanel(
                      onDelete: () {
                        ref
                            .read(tasksProvider(groupId).notifier)
                            .deleteTask(taskId: tasks.value![index].id);
                      },
                      onTap: () {
                        bool isDone = tasks.value![index].completedById != null;
                        ref.read(tasksProvider(groupId).notifier).markTask(
                            task: tasks.value![index], isDone: !isDone);
                      },
                      task: tasks.value![index],
                      isCompleted: tasks.value![index].completedById != null,
                      assignedUsers: tasks.value![index].assignedTo,
                      isOwner: isOwner);
                },
                separatorBuilder: (context, index) {
                  return const SizedBox(
                    height: 8,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );

    return tasksList;
  }
}

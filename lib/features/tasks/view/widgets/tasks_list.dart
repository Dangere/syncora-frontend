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
  const TasksList({super.key, required this.initialGroupId});

  final int initialGroupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<List<Task>> tasks = ref.watch(tasksProvider(initialGroupId));

    bool isOwner = ref.read(tasksProvider(initialGroupId).notifier).isOwner();

    Widget tasksList(List<Task> tasks) => Expanded(
          child: Column(
            children: [
              // FILTER
              FilterList<TaskFilter>(
                  onTap: (arg) {
                    ref
                        .read(tasksProvider(initialGroupId).notifier)
                        .filterTasks(arg);
                  },
                  multiSelect: true,
                  disable: false,
                  initialValue:
                      ref.read(tasksProvider(initialGroupId).notifier).filters,
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
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return TaskPanel(
                          onDelete: () {
                            ref
                                .read(tasksProvider(initialGroupId).notifier)
                                .deleteTask(taskId: tasks[index].id);
                          },
                          onTap: () {
                            bool isDone = tasks[index].completedById != null;
                            ref
                                .read(tasksProvider(initialGroupId).notifier)
                                .markTask(task: tasks[index], isDone: !isDone);
                          },
                          task: tasks[index],
                          isCompleted: tasks[index].completedById != null,
                          assignedUsers: tasks[index].assignedTo,
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

    return tasks.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        data: (data) {
          ref
              .read(loggerProvider)
              .i("Tasks Widget: building, groupId: $initialGroupId");
          return tasksList(data);
        },
        error: (error, stackTrace) {
          return Expanded(child: Center(child: Text(error.toString())));
        },
        loading: () {
          return const Expanded(
              child: Center(child: CircularProgressIndicator()));
        });
  }
}

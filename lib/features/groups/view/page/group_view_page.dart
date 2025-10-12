import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_sizes.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/core/utils/alert_dialogs.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/core/utils/validators.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/view/widgets/group_members.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';
import 'package:syncora_frontend/features/tasks/services/tasks_service.dart';
import 'package:syncora_frontend/features/tasks/view/task_assign_users_popup.dart';
import 'package:syncora_frontend/features/tasks/view/task_panel.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';
import 'package:syncora_frontend/features/tasks/viewmodel/tasks_providers.dart';
import 'package:syncora_frontend/features/users/services/users_service.dart';
import 'package:syncora_frontend/features/users/viewmodel/users_providers.dart';

class GroupViewPage extends ConsumerStatefulWidget {
  final int groupId;
  const GroupViewPage({super.key, required this.groupId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _GroupViewPageState();
}

class _GroupViewPageState extends ConsumerState<GroupViewPage> {
  @override
  Widget build(BuildContext context) {
    AsyncValue<Group> group = ref.watch(groupProvider(widget.groupId));

    SnackBarAlerts.registerErrorListener(ref, context);

    return group.when(
        // This tells .when() to IGNORE the loading state on a refresh
        // and just keep showing the previous data.
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (group) => _buildGroupView(
              group,
            ));
  }

  Widget _buildGroupView(Group group) {
    AuthState? authState = ref.watch(authNotifierProvider).valueOrNull;
    UsersService usersService = ref.read(usersServiceProvider);

    bool isOwner = authState?.user?.id == group.ownerUserId;

    void groupTitleEditPopup(String defaultText) {
      if (!isOwner) return;

      AlertDialogs.showTextFieldDialog(context,
          defaultText: defaultText,
          barrierDismissible: true,
          blurBackground: false,
          message: "Edit Group title", onContinue: (p0) {
        ref
            .read(groupsNotifierProvider.notifier)
            .updateGroupDetails(p0, null, widget.groupId);
      }, validation: (p0) {
        if (p0.trim() == defaultText) return "New title is not changed";
        return Validators.validateGroupTitle(p0) ? null : "Invalid title";
      });
    }

    void groupDescriptionEditPopup(String? defaultText) {
      if (!isOwner) return;

      AlertDialogs.showTextFieldDialog(context,
          defaultText: defaultText,
          barrierDismissible: true,
          blurBackground: false,
          message: "Edit Group Description", onContinue: (p0) {
        ref
            .read(groupsNotifierProvider.notifier)
            .updateGroupDetails(null, p0, widget.groupId);
      }, validation: (p0) {
        if (p0.trim() == defaultText) {
          return "New description is not changed";
        }
        return Validators.validateGroupDescription(p0)
            ? null
            : "Invalid description";
      });
    }

    void displayGroupDescription(String? description, bool isOwner) {
      AlertDialogs.actionsDialog(context,
          title: "Description",
          message: group.description ?? "No description.",
          actions: [
            DialogAction.closeAction(context),
            if (isOwner)
              DialogAction(
                  onClick: () {
                    Navigator.pop(context);
                    groupDescriptionEditPopup(group.description);
                    ();
                  },
                  title: "Edit"),
          ]);
    }

    void addUserToGroupPopup(int groupId) {
      if (!isOwner) return;

      AlertDialogs.showTextFieldDialog(context,
          barrierDismissible: true,
          blurBackground: false,
          message: "Add user to group",
          onContinue: (p0) {
            ref
                .read(groupsNotifierProvider.notifier)
                .allowUserAccessToGroup(groupId: groupId, username: p0.trim());
          },
          validation: (p0) => Validators.validateUsername(p0.trim())
              ? null
              : "Invalid Username");
    }

    void removeUserFromGroupPopup(int groupId, String username) {
      if (!isOwner) return;

      AlertDialogs.showTextFieldDialog(context,
          barrierDismissible: true,
          blurBackground: false,
          message: "Are you sure you want to remove user from group?",
          onContinue: (p0) {
            ref
                .read(groupsNotifierProvider.notifier)
                .removeUserAccessToGroup(groupId: groupId, username: username);
          },
          validation: (p0) => Validators.validateUsername(p0.trim())
              ? null
              : "Invalid Username");
    }

    void createTaskPopup(int groupId) {
      if (!isOwner) return;
      AlertDialogs.showTextFieldDialog(context,
          barrierDismissible: true,
          blurBackground: false,
          message: "Create new task",
          onContinue: (p0) {
            ref
                .read(groupsNotifierProvider.notifier)
                .createTask(groupId: groupId, title: p0, description: null);
          },
          validation: (p0) => null);
    }

    ref.read(loggerProvider).d("Displaying group view");
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(group.title),
            if (isOwner)
              IconButton(
                onPressed: () => groupTitleEditPopup(group.title),
                icon: const Icon(
                  Icons.edit,
                  color: Colors.grey,
                ),
              )
          ],
        ),
        actions: [
          // if (authState?.user?.id == group.ownerUserId)
          IconButton(
              padding: const EdgeInsets.all(AppSpacing.md),
              onPressed: () {
                // AlertDialogs.simpleDialog(context,
                //     title: "Description",
                //     message: group.description ?? "No description.");

                displayGroupDescription(group.description, isOwner);
              },
              icon: const Icon(Icons.info_outline))
        ],
      ),
      body: Center(
        child: FutureBuilder(
            future: usersService
                .getUsers([group.ownerUserId] + group.groupMembersIds),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              } else if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.data!.isSuccess) {
                print(snapshot.data!.error!.stackTrace?.toString());
                return Center(child: Text(snapshot.data!.error!.message));
              }

              List<User> members = snapshot.data!.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("Members"),
                  GroupMembers(
                    isOwner: isOwner,
                    group: group,
                    authState: authState,
                    addUserToGroup: () => addUserToGroupPopup(group.id),
                    members: members,
                    onMemberClick: (id) {
                      removeUserFromGroupPopup(group.id,
                          members.firstWhere((e) => e.id == id).username);
                    },
                  ),
                  // Text(group.groupMembersIds.length.toString()),
                  // Text(group.description == null || group.description!.isEmpty
                  //     ? "No description"
                  //     : group.description!),
                  Text("Tasks"),
                  _buildTasksSection(group, isOwner, members)
                ],
              );
            }),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => createTaskPopup(group.id),
        child: const Icon(Icons.add),
      ),
      // // This button will update the entire groups, but it shouldnt rebuild this widget cuz this group is supposedly listening to a change in one specific group
      // floatingActionButton: FloatingActionButton(onPressed: () {
      //   ref.read(syncBackendNotifierProvider.notifier).syncData();
      // }),
    );
  }

  // This is the section that displays the group members, TODO: make it so it has a fixed height and width regardless of available data

  Widget _buildTasksSection(Group group, bool isOwner, List<User> members) {
    TasksService tasksService = ref.read(tasksServiceProvider);

    void assignUsersPopUp(Task task) {
      TaskAssignUsersPopup.assignUsersPopUp(
        context,
        isOwner: isOwner,
        task: task,
        members: members,
        onAssign: (assignees) {
          ref.read(groupsNotifierProvider.notifier).setAssignTask(
              taskId: task.id, groupId: group.id, ids: assignees);
        },
      );
    }

    List<Color> getUserColors(List<int> ids) {
      List<User> users =
          members.where((user) => ids.contains(user.id)).toList();
      List<Color> userColors = [];
      for (User user in users) {
        userColors.add(user.userColor());
      }
      return userColors;
    }

    List<Widget> tasksListItems(List<Task> tasks) {
      return List.generate(
          tasks.length,
          (index) => Column(
                children: [
                  TaskPanel(
                    isCompleted: tasks[index].completedById != null,
                    isOwner: isOwner,
                    userColors: getUserColors(tasks[index].assignedTo),
                    task: tasks[index],
                    onDelete: () {},
                    onChange: (bool? arg) {
                      ref.read(groupsNotifierProvider.notifier).markTask(
                          taskId: tasks[index].id,
                          groupId: group.id,
                          isDone: arg ?? false);
                    },
                    onTap: () {
                      assignUsersPopUp(tasks[index]);
                    },
                  ),
                  if (index != tasks.length - 1) const Divider()
                ],
              ));
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
              color: Colors.grey[50],
              // border: Border.all(),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  spreadRadius: 0,
                  blurRadius: 5,
                  offset: const Offset(0.5, 0.5),
                )
              ],
              borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
          child: FutureBuilder(
            future: tasksService.getTasksForGroup(group.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              } else if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.data!.isSuccess) {
                print(snapshot.data!.error!.stackTrace?.toString());
                return Center(child: Text(snapshot.data!.error!.message));
              }

              List<Task> tasks = snapshot.data!.data!;

              if (tasks.isEmpty) return const Center(child: Text("No tasks"));

              return SingleChildScrollView(
                  child: Column(children: tasksListItems(tasks)));
            },
          ),
        ),
      ),
    );
  }
}

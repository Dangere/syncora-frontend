import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_sizes.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/view/popups/group_popups.dart';
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
    Widget profilePicture(WidgetRef ref, int id) {
      final double memberIconsRadius = 13;

      return FutureBuilder(
        future: ref.read(usersServiceProvider).getUserProfilePicture(id),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isSuccess) {
              // if we have no image
              if (snapshot.data!.data == null) {
                return CircleAvatar(
                  radius: memberIconsRadius,
                  child: const Icon(
                    Icons.person,
                  ),
                );
              }
              // if we have an image
              return SizedBox.square(
                dimension: memberIconsRadius * 2,
                child: Image.memory(
                  fit: BoxFit.cover,
                  snapshot.data!.data!,
                ),
              );
            } else {
              // if we have an error
              ref.read(loggerProvider).e(snapshot.data!.error!.message);
              ref.read(loggerProvider).e(snapshot.data!.error!.stackTrace);

              return const Icon(
                Icons.error,
              );
            }
          } else {
            // if we are still loading
            return const CircularProgressIndicator();
          }
        },
      );
    }

    AsyncValue<Group> groupAsync = ref.watch(groupViewProvider(widget.groupId));

    SnackBarAlerts.registerErrorListener(ref, context);

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (groupAsync.hasError && context.canPop()) {
    //     Logger().e("POPPINGG!!");
    //     context.pop();
    //   }
    // });

    Future.microtask(() {
      if (groupAsync.hasError && context.canPop()) {
        Logger().f("Popping!!, ${groupAsync.error}");
        context.pop();
      }
    });

    if ((groupAsync.isLoading && !groupAsync.hasValue) || groupAsync.hasError) {
      return Scaffold(
          appBar: AppBar(),
          body: Center(
              child: groupAsync.isLoading
                  ? const CircularProgressIndicator()
                  : Text(groupAsync.error.toString())));
    }

    Group group = groupAsync.value!;

    AuthState? authState = ref.watch(authNotifierProvider).valueOrNull;
    UsersService usersService = ref.read(usersServiceProvider);

    bool isOwner = authState?.user?.id == group.ownerUserId;

    // TODO: this page gets rebuilt like a million times cuz of the future we are watching and the notifier, optimize it king
    // ref.read(loggerProvider).d("Displaying group view");
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(group.title),
            if (isOwner)
              IconButton(
                onPressed: () => GroupPopups.groupTitleEditPopup(
                    context, ref, group.id, group.title),
                icon: const Icon(
                  Icons.edit,
                  color: Colors.grey,
                ),
              )
          ],
        ),
        actions: [
          IconButton(
              padding: const EdgeInsets.all(AppSpacing.md),
              onPressed: () {
                GroupPopups.displayGroupInfo(
                    context, ref, group, group.description, isOwner);
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
                    onAddUserButton: () =>
                        GroupPopups.addUserToGroupPopup(context, ref, group.id),
                    members: members,
                    onMemberClick: (id) {
                      if (isOwner) {
                        GroupPopups.removeUserFromGroupPopup(
                            context,
                            ref,
                            group.id,
                            members.firstWhere((e) => e.id == id).username);
                      } else {
                        context.pushNamed("profile-view",
                            pathParameters: {"id": id.toString()});
                      }
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
        onPressed: () => GroupPopups.createTaskPopup(context, ref, group.id),
        child: const Icon(Icons.add),
      ),
      // // This button will update the entire groups, but it shouldnt rebuild this widget cuz this group is supposedly listening to a change in one specific group
      // floatingActionButton: FloatingActionButton(onPressed: () {
      //   ref.read(syncBackendNotifierProvider.notifier).syncData();
      // }),
    );
  }

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
                    onDelete: () {
                      ref.read(groupsNotifierProvider.notifier).deleteTask(
                          taskId: tasks[index].id, groupId: group.id);
                    },
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/marquee_widget.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/alert_dialogs.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/view/widgets/group_members_display.dart';
import 'package:syncora_frontend/features/groups/view/popups/group_popups.dart';
import 'package:syncora_frontend/features/tasks/tasks_provider.dart';
import 'package:syncora_frontend/features/tasks/view/widgets/tasks_list.dart';
import 'package:syncora_frontend/features/groups/groups_provider.dart';
import 'package:syncora_frontend/features/users/providers/users_provider.dart';

class GroupPage extends ConsumerStatefulWidget {
  const GroupPage({super.key, required this.groupId});
  final int groupId;
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => GroupPageState();
}

class GroupPageState extends ConsumerState<GroupPage> {
  late bool isOwner;

  @override
  void initState() {
    isOwner = ref.read(groupsProvider.notifier).isGroupOwner(
        groupId: widget.groupId,
        userId: ref.read(authProvider).value!.user!.id);

    super.initState();
  }

  void addUserToGroupPopup(
      {required List<int> membersIds, required int ownerId}) async {
    // TODO: When selecting users and the group is in temp state and it syncs, it might cause issues
    List<User>? users = await AlertDialogs.selectUsersPopup(context,
        ownerId: ownerId,
        findUser: ref.read(userProvider.notifier).findUser,
        currentUsers: () => ref
            .read(groupsProvider.notifier)
            .getGroupMembers(widget.groupId, true));

    ref
        .read(loggerProvider)
        .d("Selected users: ${users?.map((e) => e.username)}");
    if (users == null) return;

    await ref.read(groupsProvider.notifier).allowUsersAccessToGroup(
        groupId: widget.groupId,
        usernames: users.map((e) => e.username).toList());
  }

  void createTaskPopup() async {
    String? taskTitle = await GroupPopups.createTaskPopup(context);
    if (taskTitle == null) return;

    ref
        .read(tasksProvider(widget.groupId).notifier)
        .createTask(title: taskTitle.trim(), description: null);
  }

  void groupExtrasPopup(Group group) async {
    return GroupPopups.groupExtrasPopup(
      context,
      isOwner: isOwner,
      onGroupInfo: () {
        ref.read(loggerProvider).d("Group extras popup");
      },
      onRenameGroup: () async {
        String? newTitle =
            await GroupPopups.groupTitleEditPopup(context, group.title);
        if (newTitle == null) return;
        ref
            .read(groupsProvider.notifier)
            .updateGroupDetails(groupId: group.id, title: newTitle);
      },
      onLeaveGroup: () {},
      onDeleteGroup: () async {
        bool confirmDeletion = await AlertDialogs.showConfirmationPopup(context,
            message: "Are you sure you want to delete this group?",
            confirmText: "Yes, Delete");

        if (confirmDeletion) {
          ref.read(groupsProvider.notifier).deleteGroup(widget.groupId);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SnackBarAlerts.registerErrorListener(ref, context);
    // This consumer will update whenever `groupViewProvider` updates BUT excludes `TasksList` because it updates itself internally

    return Consumer(
        child: TasksList(
          groupId: widget.groupId,
          isOwner: isOwner,
        ),
        builder: (context, ref, tasksList) {
          AsyncValue<Group> groupAsync =
              ref.watch(groupViewProvider(widget.groupId));
          ref.read(loggerProvider).i("Building group view page, $groupAsync ");

          if (groupAsync.error != null) {
            Navigator.pop(context);
            return Scaffold(
              body: Center(
                child: Text(groupAsync.error.toString()),
              ),
            );
          }

          if (!groupAsync.hasValue) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          Group group = groupAsync.value!;
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              // foregroundColor: Colors.transparent,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MarqueeWidget(child: Text(group.title)),
                  if (group.isInLocalState())
                    Icon(
                      Icons.sync,
                      color: Theme.of(context).colorScheme.secondary,
                    )
                ],
              ),
              centerTitle: true,
              actions: [
                // GROUP EXTRA/INFO
                IconButton(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    onPressed: () => groupExtrasPopup(group),
                    icon: const Icon(Icons.more_horiz_outlined))
              ],
            ),
            body: Stack(
              children: [
                // BACKGROUND GRAPHIC COLORS
                Positioned.fill(
                  child: Image.asset(
                      width: double.infinity,
                      // height: 371,
                      // fit: BoxFit.fitWidth,
                      alignment: Alignment.topCenter,
                      fit: BoxFit.fitWidth,
                      "assets/images/background_dashboard_effect.png"),
                ),
                //BACKGROUND GRAPHIC
                Positioned.fill(
                  child: Image.asset(
                      width: double.infinity,
                      // height: 371,
                      // fit: BoxFit.fitWidth,
                      alignment: Alignment.topCenter,
                      fit: BoxFit.fitWidth,
                      "assets/images/background_dashboard.png"),
                ),
                Column(
                  children: [
                    const SizedBox(height: 127),
                    // GROUP MEMBERS
                    GroupMembersDisplay(
                      group: group,
                      isOwner: isOwner,
                      onAddingMember: () => addUserToGroupPopup(
                          membersIds: group.groupMembersIds,
                          ownerId: group.ownerUserId),
                    ),
                    AppSpacing.verticalSpaceLg,

                    // FILTER AND TASKS
                    Expanded(
                        child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(40.0),
                            topRight: Radius.circular(40.0)),
                      ),
                      child: Column(
                        children: [
                          AppSpacing.verticalSpaceLg,
                          // TITLE AND CREATE TASK BUTTON

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // TITLE
                              Padding(
                                padding: AppSpacing.paddingHorizontalLg,
                                child: Text(
                                  AppLocalizations.of(context)
                                      .groupPage_TasksTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontWeight: FontWeight.bold),
                                ),
                              ),
                              // CREATE TASK
                              AppButton(
                                  width: 120,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg),
                                  // variant: AppButtonVariant.wide,
                                  onPressed: createTaskPopup,
                                  size: AppButtonSize.mini,
                                  style: AppButtonStyle.filled,
                                  intent: AppButtonIntent.primary,
                                  fontSize: 16,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Icon(Icons.add),
                                      Text(
                                        AppLocalizations.of(context)
                                            .groupPage_AddTaskButton,
                                      ),
                                    ],
                                  )),
                            ],
                          ),
                          AppSpacing.verticalSpaceLg,

                          // TASKS (updates itself)
                          tasksList!,
                        ],
                      ),
                    ))
                  ],
                ),
              ],
            ),
          );
        });
  }
}

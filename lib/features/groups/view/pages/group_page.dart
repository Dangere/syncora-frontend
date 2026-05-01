import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/marquee_widget.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/dialogs.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/users/models/user.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/view/widgets/group_members_display.dart';
import 'package:syncora_frontend/features/groups/view/popups/group_popups.dart';
import 'package:syncora_frontend/features/tasks/tasks_provider.dart';
import 'package:syncora_frontend/features/tasks/view/tasks_popups.dart';
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
  late bool isOwner = false;

  void addUserToGroupPopup(
      {required List<int> membersIds, required int ownerId}) async {
    // TODO: When selecting users and the group is in temp state and it syncs, it might cause issues
    List<User>? users = await GroupPopups.selectUsersPopup(context,
        ownerId: ownerId,
        findUser: ref.read(userProvider.notifier).findUser,
        currentUsers: () => ref
            .read(groupProvider(widget.groupId).notifier)
            .getGroupMembers(true));

    ref
        .read(loggerProvider)
        .d("Selected users: ${users?.map((e) => e.username)}");
    if (users == null || users.isEmpty) return;

    await ref
        .read(groupProvider(widget.groupId).notifier)
        .allowUsersAccessToGroup(users.map((e) => e.username).toList());
  }

  void createTaskPopup() async {
    String? taskTitle = await TasksPopups.createTaskPopup(context);
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
        context.pushNamed('info',
            pathParameters: {'groupId': widget.groupId.toString()});
      },
      onRenameGroup: () async {
        String? newTitle =
            await GroupPopups.groupTitleEditPopup(context, group.title);
        if (newTitle == null) return;
        ref
            .read(groupProvider(widget.groupId).notifier)
            .updateGroupDetails(groupId: group.id, title: newTitle);
      },
      onLeaveGroup: () async {
        bool confirmLeaving = await Dialogs.showConfirmationDialog(context,
            message: AppLocalizations.of(context).groupPopup_LeaveGroup_Confirm,
            confirmText: AppLocalizations.of(context).confirm);

        if (confirmLeaving) {
          await ref.read(groupProvider(widget.groupId).notifier).leaveGroup();
        }
      },
      onDeleteGroup: () async {
        bool confirmDeletion = await Dialogs.showConfirmationDialog(context,
            message:
                AppLocalizations.of(context).groupPopup_DeleteGroup_Confirm,
            confirmText: AppLocalizations.of(context).confirm);

        if (confirmDeletion) {
          await ref
              .read(groupProvider(widget.groupId).notifier)
              .deleteGroup(widget.groupId);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SnackBarAlerts.registerNotificationListener(ref, context);
    // This consumer will update whenever `groupViewProvider` updates BUT excludes `TasksList` because it updates itself internally

    return Consumer(
        child: TasksList(
          groupId: widget.groupId,
        ),
        builder: (context, innerRef, tasksList) {
          return innerRef.watch(groupProvider(widget.groupId)).when(
                skipLoadingOnRefresh: true,
                skipLoadingOnReload: true,
                data: (data) {
                  if (data == null) {
                    return Scaffold(
                        appBar: AppBar(),
                        body: Center(
                            child: Text(AppLocalizations.of(context)
                                .appError_GroupNotFound)));
                  }
                  Group group = data;

                  isOwner = innerRef
                      .read(groupProvider(widget.groupId).notifier)
                      .isGroupOwner();

                  return Scaffold(
                    extendBodyBehindAppBar: true,
                    appBar: AppBar(
                      // foregroundColor: Colors.transparent,
                      title: MarqueeWidget(
                          child: Text(data.title +
                              (kDebugMode ? " [${group.id.toString()}]" : ""))),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                      if (isOwner)
                                        // CREATE TASK
                                        AppButton(
                                          width: null,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.lg),
                                          // variant: AppButtonVariant.wide,
                                          onPressed: createTaskPopup,
                                          size: AppButtonSize.mini,
                                          style: AppButtonStyle.filled,
                                          intent: AppButtonIntent.primary,
                                          fontSize: 16,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Icon(Icons.add),
                                              AppSpacing.horizontalSpaceSm,
                                              Text(
                                                AppLocalizations.of(context)
                                                    .groupPage_AddTaskButton,
                                              ),
                                            ],
                                          ),
                                        ),
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
                },
                error: (error, stackTrace) {
                  return Scaffold(
                      appBar: AppBar(),
                      body: Center(
                        child: Text(
                          ref.read(localizeAppErrorsProvider).localizeErrorCode(
                              AppError.fromException(error, stackTrace)
                                  .errorCode,
                              context),
                        ),
                      ));
                },
                loading: () {
                  return Scaffold(
                      appBar: AppBar(),
                      body: const Center(child: CircularProgressIndicator()));
                },
              );
        });
  }
}

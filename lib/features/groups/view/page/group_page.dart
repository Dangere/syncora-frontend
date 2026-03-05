import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/marquee_widget.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/view/widgets/group_members_display.dart';
import 'package:syncora_frontend/features/groups/view/popups/group_popups.dart';
import 'package:syncora_frontend/features/tasks/tasks_provider.dart';
import 'package:syncora_frontend/features/tasks/view/widgets/tasks_list.dart';
import 'package:syncora_frontend/features/groups/groups_provider.dart';

// This consumer will update whenever `groupViewProvider` updates BUT excludes `TasksList` because it updates itself internally
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

  void addUserToGroupPopup() async {
    String? username = await GroupPopups.addUserToGroupPopup(
      context,
      users: (ids: [], usernames: []),
      addUser: ({required username}) {
        return ref.read(groupsProvider.notifier).allowUserAccessToGroup(
            groupId: widget.groupId, username: username.trim());
      },
    );
    if (username == null) return;

    ref.read(groupsProvider.notifier).allowUserAccessToGroup(
        groupId: widget.groupId, username: username.trim());
  }

  void createTaskPopup() async {
    String? taskTitle = await GroupPopups.createTaskPopup(context);
    if (taskTitle == null) return;

    ref
        .read(tasksProvider(widget.groupId).notifier)
        .createTask(title: taskTitle.trim(), description: null);
  }

  @override
  Widget build(BuildContext context) {
    SnackBarAlerts.registerErrorListener(ref, context);

    return Consumer(
        child: TasksList(
          groupId: widget.groupId,
        ),
        builder: (context, ref, tasksList) {
          AsyncValue<Group> groupAsync =
              ref.watch(groupViewProvider(widget.groupId));
          ref.read(loggerProvider).i("Building group view page, $groupAsync ");

          if (!groupAsync.hasValue) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          Group group = groupAsync.value!;
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              // foregroundColor: Colors.transparent,
              title: MarqueeWidget(child: Text(group.title)),
              centerTitle: true,
              actions: [
                // GROUP EXTRA/INFO
                IconButton(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    onPressed: () {
                      // GroupPopups.displayGroupInfo(
                      //     context, ref, group, group.description, isOwner);
                    },
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
                      onAddingMember: addUserToGroupPopup,
                    ),
                    AppSpacing.verticalSpaceLg,

                    // FILTER AND GROUPS
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
                                      .dashboardPage_MyGroups,
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
                                  size: AppButtonSize.small,
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

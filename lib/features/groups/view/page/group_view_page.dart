import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_sizes.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/marquee_text.dart';
import 'package:syncora_frontend/core/network/syncing/sync_notifier.dart';
import 'package:syncora_frontend/core/utils/alert_dialogs.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/core/utils/validators.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';
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

    void groupTitleEditPopup(String defaultText) {
      AlertDialogs.showTextFieldDialog(context,
          defaultText: defaultText,
          barrierDismissible: true,
          blurBackground: false,
          message: "Edit Group title", onContinue: (p0) {
        ref
            .read(groupsNotifierProvider.notifier)
            .updateGroupDetail(p0, null, widget.groupId);
      }, validation: (p0) {
        if (p0.trim() == defaultText) return "New title is not changed";
        return Validators.validateGroupTitle(p0) ? null : "Invalid title";
      });
    }

    void groupDescriptionEditPopup(String? defaultText) {
      AlertDialogs.showTextFieldDialog(context,
          defaultText: defaultText,
          barrierDismissible: true,
          blurBackground: false,
          message: "Edit Group Description", onContinue: (p0) {
        ref
            .read(groupsNotifierProvider.notifier)
            .updateGroupDetail(null, p0, widget.groupId);
      }, validation: (p0) {
        if (p0.trim() == defaultText) {
          return "New description is not changed";
        }
        return Validators.validateGroupDescription(p0)
            ? null
            : "Invalid description";
      });
    }

    void addUserToGroup(int groupId) {
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

    void createTask(int groupId, String taskContent) {
      AlertDialogs.showTextFieldDialog(context,
          barrierDismissible: true,
          blurBackground: false,
          message: "Create new task",
          onContinue: (p0) {
            ref
                .read(groupsNotifierProvider.notifier)
                .allowUserAccessToGroup(groupId: groupId, username: p0.trim());
          },
          validation: (p0) => null);
    }

    return group.when(
        // This tells .when() to IGNORE the loading state on a refresh
        // and just keep showing the previous data.
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (group) => _buildGroupView(
              group,
              editGroupTitle: () => groupTitleEditPopup(group.title),
              editGroupDescription: () =>
                  groupDescriptionEditPopup(group.description),
              addUserToGroup: () => addUserToGroup(group.id),
            ));
  }

  Widget _buildGroupView(Group group,
      {required VoidCallback editGroupTitle,
      required VoidCallback editGroupDescription,
      required VoidCallback addUserToGroup}) {
    AuthState? authState = ref.watch(authNotifierProvider).valueOrNull;

    ref.read(loggerProvider).d("Displaying group view");
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(group.title),
            IconButton(
              onPressed: editGroupTitle,
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

                AlertDialogs.actionsDialog(context,
                    title: "Description",
                    message: group.description ?? "No description.",
                    actions: [
                      DialogAction.closeAction(context),
                      if (authState?.user?.id == group.ownerUserId)
                        DialogAction(
                            onClick: () {
                              Navigator.pop(context);
                              editGroupDescription();
                            },
                            title: "Edit"),
                    ]);
              },
              icon: const Icon(Icons.info_outline))
        ],
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Members"),
            _buildMembersSection(group, authState, addUserToGroup),
            // Text(group.groupMembersIds.length.toString()),
            // Text(group.description == null || group.description!.isEmpty
            //     ? "No description"
            //     : group.description!),
            Text("Tasks"),
          ],
        ),
      ),
      // This button will update the groups, but we shouldnt rebuild this widget cuz we are supposedly listening to a change in one specific group
      floatingActionButton: FloatingActionButton(onPressed: () {
        ref.read(syncBackendNotifierProvider.notifier).syncData();
      }),
    );
  }

  // This is the section that displays the group members
  Widget _buildMembersSection(
      Group group, AuthState? authState, VoidCallback addUserToGroup) {
    UsersService usersService = ref.read(usersServiceProvider);

    List<Widget> membersListItems(List<User> users) {
      String displayName(User user) {
        return user.username +
            ((user.id == authState?.user?.id) ? " (You)" : "") +
            ((user.id == group.ownerUserId) ? " (Owner)" : "");
      }

      List<Widget> members = List.generate(
          users.length > 10 ? 10 : users.length,
          (index) => Padding(
                padding: const EdgeInsets.all(5.0),
                child: SizedBox(
                  width: 70,
                  child: Column(
                    children: [
                      SizedBox(
                        child: CircleAvatar(
                          backgroundColor: users[index].userColor(),
                          radius: 30,
                          child: const Icon(
                            Icons.person,
                          ),
                        ),
                      ),
                      MarqueeText(
                        child: Text(displayName(users[index]),
                            style: Theme.of(context).textTheme.bodySmall),
                      )
                    ],
                  ),
                ),
              ));

      Widget addMemberButton() => Padding(
            padding: const EdgeInsets.all(2.0),
            child: SizedBox(
              width: 70,
              child: Column(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.group_add_rounded,
                      color: Colors.grey,
                    ),
                    onPressed: addUserToGroup,
                  )
                ],
              ),
            ),
          );

      members.add(addMemberButton());

      return members;
    }

    return FutureBuilder(
        future:
            usersService.getUsers([group.ownerUserId] + group.groupMembersIds),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          } else if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }

          List<User> users = snapshot.data!.data!;

          return Padding(
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
                      offset: Offset(0.5, 0.5),
                    )
                  ],
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: membersListItems(users),
                ),
              ),
            ),
          );
        });
  }
}

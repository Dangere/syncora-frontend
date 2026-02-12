import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/core/utils/alert_dialogs.dart';
import 'package:syncora_frontend/core/utils/date_utilities.dart';
import 'package:syncora_frontend/core/utils/validators.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';

class GroupPopups {
  static void displayGroupInfo(BuildContext context, WidgetRef ref, Group group,
      String? description, bool isOwner) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.info),

          // actionsOverflowAlignment: OverflowBarAlignment.center,
          title: Text(
            "Group Info",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          content: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Description",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (isOwner)
                      IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();

                            groupDescriptionEditPopup(
                                context, ref, group.id, description);
                          },
                          icon: const Icon(Icons.edit)),
                  ],
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    description ?? "",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Divider(),
                Text(
                  "Created in: ${DateUtilities.getFormattedDate(group.creationDate.toLocal())}",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),

          actions: [
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Ok")),
            if (isOwner)
              ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref
                        .read(groupsNotifierProvider.notifier)
                        .deleteGroup(group.id);
                  },
                  child: const Text("DELETE",
                      style: TextStyle(color: Colors.black))),
            if (!isOwner)
              ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref
                        .read(groupsNotifierProvider.notifier)
                        .leaveGroup(group.id);
                  },
                  child: const Text("LEAVE",
                      style: TextStyle(color: Colors.black))),
          ],
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.all(15),
        );
      },
    );
  }

  static void groupTitleEditPopup(
      BuildContext context, WidgetRef ref, int groupId, String defaultText) {
    AlertDialogs.showTextFieldDialog(context,
        defaultText: defaultText,
        barrierDismissible: true,
        blurBackground: false,
        message: "Edit Group title", onContinue: (p0) {
      ref
          .read(groupsNotifierProvider.notifier)
          .updateGroupDetails(p0, null, groupId);
    }, validation: (p0) {
      if (p0.trim() == defaultText) return "New title is not changed";
      return Validators.validateGroupTitle(p0) ? null : "Invalid title";
    });
  }

  static void groupDescriptionEditPopup(
      BuildContext context, WidgetRef ref, int groupId, String? defaultText) {
    AlertDialogs.showTextFieldDialog(context,
        defaultText: defaultText,
        barrierDismissible: true,
        blurBackground: false,
        message: "Edit Group Description", onContinue: (p0) {
      ref
          .read(groupsNotifierProvider.notifier)
          .updateGroupDetails(null, p0, groupId);
    }, validation: (p0) {
      if (p0.trim() == defaultText) {
        return "New description is not changed";
      }
      return Validators.validateGroupDescription(p0)
          ? null
          : "Invalid description";
    });
  }

  static void addUserToGroupPopup(
      BuildContext context, WidgetRef ref, int groupId) {
    AlertDialogs.showTextFieldDialog(context,
        defaultHintText: "Username",
        barrierDismissible: true,
        blurBackground: false,
        message: "Add user to group",
        onContinue: (p0) {
          ref
              .read(groupsNotifierProvider.notifier)
              .allowUserAccessToGroup(groupId: groupId, username: p0.trim());
        },
        validation: (p0) =>
            Validators.validateUsername(p0.trim()) ? null : "Invalid Username");
  }

  static void removeUserFromGroupPopup(
      BuildContext context, WidgetRef ref, int groupId, String username) {
    AlertDialogs.showTextFieldDialog(context,
        barrierDismissible: true,
        blurBackground: false,
        message: "Are you sure you want to remove user from group?",
        onContinue: (p0) {
          ref
              .read(groupsNotifierProvider.notifier)
              .removeUserAccessToGroup(groupId: groupId, username: username);
        },
        validation: (p0) =>
            Validators.validateUsername(p0.trim()) ? null : "Invalid Username");
  }

  static void createTaskPopup(
      BuildContext context, WidgetRef ref, int groupId) {
    AlertDialogs.showTextFieldDialog(context,
        barrierDismissible: true,
        blurBackground: false,
        message: "Create new task",
        onContinue: (p0) {
          ref
              .read(groupsNotifierProvider.notifier)
              .createTask(groupId: groupId, title: p0, description: null);
        },
        validation: (p0) =>
            Validators.validateGroupTitle(p0) ? null : "Invalid task title");
  }

  static void createGroupPopup(BuildContext context, WidgetRef ref) async {
    String? title;
    String? description;

    // TITLE POPUP
    await AlertDialogs.showTextFieldDialog(context,
        barrierDismissible: true,
        blurBackground: false,
        message: "New Group title",
        onContinue: (p0) {
          title = p0;
        },
        validation: (p0) =>
            Validators.validateGroupTitle(p0) ? null : "Invalid title");

    if (title != null && context.mounted) {
      await AlertDialogs.showTextFieldDialog(context,
          barrierDismissible: true,
          blurBackground: false,
          message: "New Group description",
          onContinue: (p0) {
            description = p0;
          },
          validation: (p0) => Validators.validateGroupDescription(p0)
              ? null
              : "Invalid description");
    }

    if (title != null && description != null) {
      ref
          .read(groupsNotifierProvider.notifier)
          .createGroup(title: title!, description: description!);
    }
  }
}

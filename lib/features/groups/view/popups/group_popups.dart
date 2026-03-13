import 'package:flutter/material.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/core/utils/alert_dialogs.dart';
import 'package:syncora_frontend/core/utils/validators.dart';

class GroupPopups {
  static Future<String?> groupTitleEditPopup(
      BuildContext context, String defaultText) async {
    List<String> data = await AlertDialogs.showTextFieldDialog(
      context,
      fields: [
        DialogFieldData(
            validation: (p0) {
              if (p0 == null || p0.trim().isEmpty) return "Empty title";
              if (p0.trim() == defaultText) return "New title is not changed";
              return Validators.validateGroupTitle(p0) ? null : "Invalid title";
            },
            label: "Group Title",
            defaultText: defaultText)
      ],
      barrierDismissible: true,
      blurBackground: false,
      title: "Edit Group title",
      confirmText: "Rename",
    );

    return data.isEmpty ? null : data[0];
  }

  static Future<String?> groupDescriptionEditPopup(
      BuildContext context, String defaultText) async {
    List<String> data = await AlertDialogs.showTextFieldDialog(
      context,
      fields: [
        DialogFieldData(
          multiLine: true,
          validation: (p0) {
            if (p0 == null || p0.trim().isEmpty) return "Empty Description";
            if (p0.trim() == defaultText)
              return "New description is not changed";
            return Validators.validateGroupDescription(p0)
                ? null
                : "Invalid description";
          },
          label: "Group Description",
          defaultHintText: defaultText,
        )
      ],
      barrierDismissible: true,
      blurBackground: false,
      title: "Edit Group description",
      confirmText: "Save",
    );

    return data.isEmpty ? null : data[0];
  }

  static Future<String?> removeUserFromGroupPopup(
      BuildContext context, String username) async {
    List<String> data = await AlertDialogs.showTextFieldDialog(
      context,
      fields: [
        DialogFieldData(
          validation: (p0) {
            if (p0 == null || p0.trim().isEmpty) return "Empty Username";
            return Validators.validateUsername(p0.trim())
                ? null
                : "Invalid Username";
          },
          label: "Username",
          defaultHintText: username,
        )
      ],
      barrierDismissible: true,
      blurBackground: false,
      title: "Are you sure you want to remove user from group?",
      confirmText: "Remove",
    );

    return data.isEmpty ? null : data[0];
  }

  static Future<String?> createTaskPopup(BuildContext context) async {
    List<String> data = await AlertDialogs.showTextFieldDialog(
      context,
      fields: [
        DialogFieldData(
            label: "Task Title",
            defaultHintText: "Enter the title",
            validation: (p0) {
              if (p0 == null || p0.trim().isEmpty) return "Empty task title";

              return Validators.validateGroupTitle(p0)
                  ? null
                  : "Invalid task title";
            })
      ],
      barrierDismissible: true,
      blurBackground: false,
      title: "Add a New Task",
      confirmText: "Add",
    );

    return data.isEmpty ? null : data[0];
  }

  static Future<({String title, String description})?> createGroupPopup(
      BuildContext context) async {
    List<String> data = await AlertDialogs.showTextFieldDialog(
      context,
      fields: [
        DialogFieldData(
            label: "Group Title",
            defaultHintText: "Enter the title",
            validation: (p0) {
              if (p0 == null || p0.trim().isEmpty) return "Empty group title";

              return Validators.validateGroupTitle(p0)
                  ? null
                  : "Invalid group title";
            }),
        DialogFieldData(
            multiLine: true,
            label: "Task Description",
            defaultHintText: "Enter the description",
            validation: (p0) {
              if (p0 == null || p0.trim().isEmpty)
                return "Empty group description";

              return Validators.validateGroupDescription(p0)
                  ? null
                  : "Invalid group description";
            })
      ],
      barrierDismissible: true,
      blurBackground: false,
      title: "New Group",
      confirmText: "Create",
    );

    if (data.isEmpty) return null;

    return (title: data[0], description: data[1]);
  }

  // Void popups / Content Pop ups
  static Future<void> groupExtrasPopup(BuildContext context,
      {required VoidCallback onGroupInfo,
      required VoidCallback onRenameGroup,
      required VoidCallback onDeleteGroup,
      required VoidCallback onLeaveGroup,
      required bool isOwner}) async {
    await AlertDialogs.showContentDialog(
      context,
      barrierDismissible: true,
      blurBackground: false,
      title: "More Options",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Group info
          AppButton(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              size: AppButtonSize.mini,
              style: AppButtonStyle.filled,
              onPressed: () {
                Navigator.pop(context);
                onGroupInfo();
              },
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    size: 24,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(
                    width: 17,
                  ),
                  Text("More Info About This Group",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.outline)),
                ],
              )),
          const SizedBox(
            height: 8,
          ),
          // Rename group
          if (isOwner)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: AppButton(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  size: AppButtonSize.mini,
                  style: AppButtonStyle.filled,
                  onPressed: () {
                    Navigator.pop(context);
                    onRenameGroup();
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                        size: 24,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(
                        width: 17,
                      ),
                      Text("Rename Group",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.outline)),
                    ],
                  )),
            ),

          // DELETE / LEAVE GROUP
          AppButton(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              size: AppButtonSize.mini,
              style: AppButtonStyle.filled,
              intent: AppButtonIntent.destructive,
              onPressed: () {
                Navigator.pop(context);
                if (isOwner) {
                  onDeleteGroup();
                } else {
                  onLeaveGroup();
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.exit_to_app_outlined, size: 24),
                  const SizedBox(
                    width: 17,
                  ),
                  Text(isOwner ? "Delete Group" : "Leave Group"),
                ],
              )),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/input_field.dart';
import 'package:syncora_frontend/common/widgets/profile_picture.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/dialogs.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/core/utils/validators.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';

class GroupPopups {
  static Future<String?> groupTitleEditPopup(
      BuildContext context, String defaultText) async {
    List<String> data = await Dialogs.showTextFieldDialog(
      context,
      fields: [
        DialogFieldData(
            autofocus: true,
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
    List<String> data = await Dialogs.showTextFieldDialog(
      context,
      fields: [
        DialogFieldData(
          autofocus: true,
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
          defaultText: defaultText,
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
    List<String> data = await Dialogs.showTextFieldDialog(
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
    List<String> data = await Dialogs.showTextFieldDialog(
      context,
      fields: [
        DialogFieldData(
            autofocus: true,
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
    List<String> data = await Dialogs.showTextFieldDialog(
      context,
      fields: [
        DialogFieldData(
            autofocus: true,
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
    await Dialogs.showContentDialog(
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
                Navigator.of(context).pop();
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
                    Navigator.of(context).pop();
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
                Navigator.of(context).pop();
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

  static Future<List<User>?> selectUsersPopup(BuildContext context,
      {required Future<User?> Function(String username) findUser,
      required Future<List<User>> Function() currentUsers,
      required int ownerId}) async {
    List<User> users = [];
    TextEditingController textEditingController = TextEditingController();
    final fieldKey = GlobalKey<FormFieldState>();

    bool isLoading = false;

    Future onConfirm(
        String username, void Function(void Function()) setState) async {
      isLoading = true;
      // If the text field is empty, we confirm selection and return it
      if (textEditingController.text.isEmpty) {
        if (users.isEmpty) {
          if (!context.mounted) return;
          SnackBarAlerts.showAlertSnackBar("No users selected", context);
        }
        Navigator.of(context).pop(users);
        return;
      }

      // If the text field is not empty, we validate it
      if (!fieldKey.currentState!.validate()) return;

      List<User> members = await currentUsers();
      // If the user is the owner, we show a warning
      if (members.where((user) => user.username == username).firstOrNull?.id ==
          ownerId) {
        if (!context.mounted) return;
        SnackBarAlerts.showAlertSnackBar("You can't add yourself", context);
        return;
      }

      // If the user is already in the list or a member of the group, we show a warning
      if (users
              .where((user) =>
                  user.username.toLowerCase() == username.toLowerCase())
              .isNotEmpty ||
          members
              .where((user) =>
                  user.username.toLowerCase() == username.toLowerCase())
              .isNotEmpty) {
        if (!context.mounted) return;
        SnackBarAlerts.showAlertSnackBar("User already added", context);
        return;
      }

      // If the text field is valid, we add the user
      User? addedUser = await findUser(textEditingController.text);

      // If the user was not found, we show an error
      if (addedUser == null) {
        if (!context.mounted) return;
        SnackBarAlerts.showErrorSnackBar("User not found", context);
        return;
      }
      // If the user was found, we add it to the list
      setState(() {
        users.add(addedUser);
        textEditingController.clear();
      });
    }

    void onRemoveUser(int id, void Function(void Function()) setState) async {
      // We remove the user from the list
      setState(() {
        users.removeWhere((user) => user.id == id);
      });
    }

    return await Dialogs.showContentDialog<List<User>?>(context,
        barrierDismissible: true,
        blurBackground: false,
        title: "Add a New Member",
        content: StatefulBuilder(builder: (context, setState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // FIELD
          InputField(
              autoFocus: true,
              fieldKey: fieldKey,
              controller: textEditingController,
              validator: (arg) {
                if (arg == null || arg.trim().isEmpty) {
                  return "Empty username";
                }
                return Validators.validateUsername(arg)
                    ? null
                    : "Invalid username";
              },
              labelText: "Member Username",
              hintText: AppLocalizations.of(context).signUpPage_Username_Field,
              suffixIcon:
                  textEditingController.text.isEmpty ? null : Icons.close,
              onSuffixIconPressed: () {
                setState(() {
                  textEditingController.clear();
                });
              },
              onChanged: (arg) {
                setState(() {});
              },
              keyboardType: TextInputType.name),
          const SizedBox(
            height: 24,
          ),
          // USERS
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 100),
            child: SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  spacing: 5,
                  runSpacing: 10,
                  children: users
                      .map((user) => Container(
                            height: 35,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              borderRadius: BorderRadius.circular(90),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: ProfilePicture(
                                    userId: user.id,
                                    imageUrl: user.pfpURL,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  user.username,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 2),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: GestureDetector(
                                    onTap: () =>
                                        onRemoveUser(user.id, setState),
                                    child: Icon(
                                      Icons.close,
                                      size: 24,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainer,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
          if (users.isNotEmpty)
            const SizedBox(
              height: 24,
            ),
          // ADD
          AppButton(
              size: AppButtonSize.small,
              style: AppButtonStyle.filled,
              intent: AppButtonIntent.primary,
              fontSize: 20,
              onPressed: () async {
                if (!isLoading) {
                  await onConfirm(textEditingController.text, setState);
                  isLoading = false;
                }
              },
              child:
                  Text(textEditingController.text.isEmpty ? "Confirm" : "Add"))
        ],
      );
    }));
  }
}

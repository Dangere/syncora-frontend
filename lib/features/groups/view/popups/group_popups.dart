import 'package:flutter/material.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/input_field.dart';
import 'package:syncora_frontend/common/widgets/profile_picture.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/dialogs.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/core/utils/validators.dart';
import 'package:syncora_frontend/features/users/models/user.dart';

class GroupPopups {
  static Future<String?> groupTitleEditPopup(
      BuildContext context, String defaultText) async {
    final l10n = AppLocalizations.of(context);
    List<String> data = await Dialogs.showTextFieldDialog(
      context,
      fields: [
        DialogFieldData(
            autofocus: true,
            validation: (p0) {
              if (p0 == null || p0.trim().isEmpty)
                return l10n.validation_GroupTitle_Empty;
              if (p0.trim() == defaultText)
                return l10n.validation_GroupTitle_Unchanged;
              return Validators.validateGroupTitle(p0)
                  ? null
                  : l10n.validation_GroupTitle_Invalid;
            },
            label: l10n.groupPopup_GroupTitle_Label,
            defaultText: defaultText)
      ],
      barrierDismissible: true,
      blurBackground: false,
      title: l10n.groupPopup_EditTitle,
      confirmText: l10n.rename,
    );

    return data.isEmpty ? null : data[0];
  }

  static Future<String?> groupDescriptionEditPopup(
      BuildContext context, String defaultText) async {
    final l10n = AppLocalizations.of(context);
    List<String> data = await Dialogs.showTextFieldDialog(
      context,
      fields: [
        DialogFieldData(
          autofocus: true,
          multiLine: true,
          validation: (p0) {
            if (p0 == null || p0.trim().isEmpty)
              return l10n.validation_GroupDescription_Empty;
            if (p0.trim() == defaultText)
              return l10n.validation_GroupDescription_Unchanged;
            return Validators.validateGroupDescription(p0)
                ? null
                : l10n.validation_GroupDescription_Invalid;
          },
          label: l10n.groupPopup_GroupDescription_Label,
          defaultText: defaultText,
        )
      ],
      barrierDismissible: true,
      blurBackground: false,
      title: l10n.groupPopup_EditDescription,
      confirmText: l10n.save,
    );

    return data.isEmpty ? null : data[0];
  }

  static Future<String?> removeUserFromGroupPopup(
      BuildContext context, String username) async {
    final l10n = AppLocalizations.of(context);
    List<String> data = await Dialogs.showTextFieldDialog(
      context,
      fields: [
        DialogFieldData(
          validation: (p0) {
            if (p0 == null || p0.trim().isEmpty)
              return l10n.validation_Username_Empty;
            return Validators.validateUsername(p0.trim())
                ? null
                : l10n.validation_Username_Invalid;
          },
          label: l10n.signUpPage_Username,
          defaultHintText: username,
        )
      ],
      barrierDismissible: true,
      blurBackground: false,
      title: l10n.groupPopup_RemoveUser_Title,
      confirmText: l10n.remove,
    );

    return data.isEmpty ? null : data[0];
  }

  static Future<({String title, String description})?> createGroupPopup(
      BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    List<String> data = await Dialogs.showTextFieldDialog(
      context,
      fields: [
        DialogFieldData(
            autofocus: true,
            label: l10n.groupPopup_GroupTitle_Label,
            defaultHintText: l10n.groupPopup_GroupTitle_Hint,
            validation: (p0) {
              if (p0 == null || p0.trim().isEmpty)
                return l10n.validation_GroupTitle_Create_Empty;
              return Validators.validateGroupTitle(p0)
                  ? null
                  : l10n.validation_GroupTitle_Create_Invalid;
            }),
        DialogFieldData(
            multiLine: true,
            label: l10n.groupPopup_GroupDescription_Label,
            defaultHintText: l10n.groupPopup_GroupDescription_Hint,
            validation: (p0) {
              if (p0 == null || p0.trim().isEmpty)
                return l10n.validation_GroupDescription_Create_Empty;
              return Validators.validateGroupDescription(p0)
                  ? null
                  : l10n.validation_GroupDescription_Create_Invalid;
            })
      ],
      barrierDismissible: true,
      blurBackground: false,
      title: l10n.groupPopup_CreateGroup_Title,
      confirmText: l10n.create,
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
    final l10n = AppLocalizations.of(context);
    await Dialogs.showContentDialog(
      context,
      barrierDismissible: true,
      blurBackground: false,
      title: l10n.moreOptions,
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
                  const SizedBox(width: 17),
                  Text(l10n.groupPopup_MoreInfo,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.outline)),
                ],
              )),
          const SizedBox(height: 8),
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
                      const SizedBox(width: 17),
                      Text(l10n.groupPopup_RenameGroup,
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
                  const SizedBox(width: 17),
                  Text(isOwner
                      ? l10n.groupPopup_DeleteGroup
                      : l10n.groupPopup_LeaveGroup),
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
      final l10n = AppLocalizations.of(context);

      // If the text field is empty, we confirm selection and return it
      if (textEditingController.text.isEmpty) {
        if (users.isEmpty) {
          if (!context.mounted) return;
          SnackBarAlerts.showAlertSnackBar(
              l10n.groupPopup_Alert_NoUsersSelected, context);
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
        SnackBarAlerts.showAlertSnackBar(
            l10n.groupPopup_Alert_CantAddSelf, context);
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
        SnackBarAlerts.showAlertSnackBar(
            l10n.groupPopup_Alert_UserAlreadyAdded, context);
        return;
      }

      // If the text field is valid, we add the user
      User? addedUser = await findUser(textEditingController.text);

      // If the user was not found, we show an error
      if (addedUser == null) {
        if (!context.mounted) return;
        SnackBarAlerts.showErrorSnackBar(
            l10n.groupPopup_Error_UserNotFound, context);
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
        title: AppLocalizations.of(context).groupPopup_AddMember_Title,
        content: StatefulBuilder(builder: (context, setState) {
      final l10n = AppLocalizations.of(context);
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
                  return l10n.validation_Username_Empty;
                }
                return Validators.validateUsername(arg)
                    ? null
                    : l10n.validation_Username_Invalid;
              },
              labelText: l10n.signUpPage_Username,
              hintText: l10n.signUpPage_Username_Field,
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
          const SizedBox(height: 24),
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
          if (users.isNotEmpty) const SizedBox(height: 24),
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
              child: Text(
                  textEditingController.text.isEmpty ? l10n.confirm : l10n.add))
        ],
      );
    }));
  }
}

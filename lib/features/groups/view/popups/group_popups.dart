import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/input_field.dart';
import 'package:syncora_frontend/common/widgets/profile_picture.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/alert_dialogs.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/core/utils/validators.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';

class GroupPopups {
  // static void displayGroupInfo(BuildContext context, WidgetRef ref, Group group,
  //     String? description, bool isOwner) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         icon: const Icon(Icons.info),

  //         // actionsOverflowAlignment: OverflowBarAlignment.center,
  //         title: Text(
  //           "Group Info",
  //           style: Theme.of(context).textTheme.titleMedium,
  //         ),
  //         content: IntrinsicHeight(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Text(
  //                     "Description",
  //                     style: Theme.of(context).textTheme.titleMedium,
  //                   ),
  //                   if (isOwner)
  //                     IconButton(
  //                         onPressed: () {
  //                           Navigator.of(context).pop();

  //                           groupDescriptionEditPopup(
  //                               context, ref, group.id, description);
  //                         },
  //                         icon: const Icon(Icons.edit)),
  //                 ],
  //               ),
  //               Container(
  //                 width: MediaQuery.of(context).size.width * 0.8,
  //                 padding: const EdgeInsets.all(8.0),
  //                 decoration: BoxDecoration(
  //                   color: Theme.of(context).cardColor,
  //                   border: Border.all(color: Colors.grey.withOpacity(0.5)),
  //                   borderRadius: BorderRadius.circular(10),
  //                 ),
  //                 child: Text(
  //                   description ?? "",
  //                   style: Theme.of(context).textTheme.bodySmall,
  //                 ),
  //               ),
  //               const Divider(),
  //               Text(
  //                 "Created in: ${DateUtilities.getFormattedDate(group.creationDate.toLocal())}",
  //                 style: Theme.of(context).textTheme.titleMedium,
  //               ),
  //             ],
  //           ),
  //         ),

  //         actions: [
  //           ElevatedButton(
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //               },
  //               child: const Text("Ok")),
  //           if (isOwner)
  //             ElevatedButton(
  //                 style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                   ref.read(groupsProvider.notifier).deleteGroup(group.id);
  //                 },
  //                 child: const Text("DELETE",
  //                     style: TextStyle(color: Colors.black))),
  //           if (!isOwner)
  //             ElevatedButton(
  //                 style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                   ref.read(groupsProvider.notifier).leaveGroup(group.id);
  //                 },
  //                 child: const Text("LEAVE",
  //                     style: TextStyle(color: Colors.black))),
  //         ],
  //         actionsAlignment: MainAxisAlignment.spaceBetween,
  //         actionsPadding: const EdgeInsets.all(15),
  //       );
  //     },
  //   );
  // }

  static Future<String?> groupTitleEditPopup(
      BuildContext context, String defaultText) async {
    return AlertDialogs.showTextFieldDialog(context,
        defaultText: defaultText,
        barrierDismissible: true,
        blurBackground: false,
        message: "Edit Group title", validation: (p0) {
      if (p0 == null || p0.trim().isEmpty) return "Empty title";
      if (p0.trim() == defaultText) return "New title is not changed";
      return Validators.validateGroupTitle(p0) ? null : "Invalid title";
    });
  }

  // static Future<String?> groupDescriptionEditPopup(
  //     BuildContext context, String? defaultText) async {
  //   return AlertDialogs.showTextFieldDialog(context,
  //       defaultText: defaultText,
  //       barrierDismissible: true,
  //       blurBackground: false,
  //       message: "Edit Group Description", validation: (p0) {
  //     if (p0 == null || p0.trim().isEmpty) return "Empty description";
  //     if (p0.trim() == defaultText) {
  //       return "New description is not changed";
  //     }
  //     return Validators.validateGroupDescription(p0)
  //         ? null
  //         : "Invalid description";
  //   });
  // }

  static Future<List<User>?> selectUsersForAddingPopup(BuildContext context,
      {required Future<User?> Function(String username) findUser,
      required Future<List<User>> Function() currentMembers,
      required int ownerId}) async {
    List<User> users = [];
    TextEditingController textEditingController = TextEditingController();
    final fieldKey = GlobalKey<FormFieldState>();

    bool isLoading = false;

    void onMainButton(
        String username, void Function(void Function()) setState) async {
      // If the text field is empty, we confirm selection and return it
      if (textEditingController.text.isEmpty) {
        Navigator.of(context).pop(users);
        return;
      }
      if (isLoading) return;
      isLoading = true;

      // If the text field is not empty, we validate it
      if (!fieldKey.currentState!.validate()) return;

      List<User> members = await currentMembers();
      Logger().d(members.map((e) => e.username).toList());
      // If the user is the owner, we show a warning
      if (members.where((user) => user.username == username).firstOrNull?.id ==
          ownerId) {
        if (!context.mounted) return;
        SnackBarAlerts.showAlertSnackBar("You can't add yourself", context);
        isLoading = false;
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
        isLoading = false;
        return;
      }

      // If the text field is valid, we add the user
      User? addedUser = await findUser(textEditingController.text);

      // If the user was not found, we show an error
      if (addedUser == null) {
        if (!context.mounted) return;
        SnackBarAlerts.showErrorSnackBar("User not found", context);
        isLoading = false;
        return;
      }
      // If the user was found, we add it to the list
      setState(() {
        users.add(addedUser);
        textEditingController.clear();
      });

      isLoading = false;
    }

    void onRemoveUser(int id, void Function(void Function()) setState) async {
      // We remove the user from the list
      setState(() {
        users.removeWhere((user) => user.id == id);
      });
    }

    return showDialog<List<User>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            contentPadding: const EdgeInsets.all(0),
            content: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TITLE AND CLOSE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(child: SizedBox()),
                        Expanded(
                          flex: 5,
                          child: Text(
                            "Add a New Member",
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                            child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            size: 24,
                            Icons.close,
                          ),
                        ))
                      ],
                    ),
                    const SizedBox(
                      height: 24,
                    ),
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
                        hintText: AppLocalizations.of(context)
                            .signUpPage_Username_Field,
                        suffixIcon: textEditingController.text.isEmpty
                            ? null
                            : Icons.close,
                        onSuffixIconPressed: () {
                          setState(() {
                            textEditingController.clear();
                          });
                        },
                        onChanged: (arg) {
                          setState(() {});
                        },
                        keyboardType: TextInputType.none),
                    const SizedBox(
                      height: 24,
                    ),
                    // USERNAMES
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: SingleChildScrollView(
                        child: Wrap(
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          spacing: 12,
                          runSpacing: 10,
                          children: users
                              .map((e) => Container(
                                    height: 35,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      borderRadius: BorderRadius.circular(90),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          child: ProfilePicture(
                                            userId: e.id,
                                            imageUrl: e.pfpURL,
                                          ),
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          e.username,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .copyWith(
                                                  fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(width: 2),
                                        Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: GestureDetector(
                                            onTap: () =>
                                                onRemoveUser(e.id, setState),
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
                        onPressed: () =>
                            onMainButton(textEditingController.text, setState),
                        child: Text(textEditingController.text.isEmpty
                            ? "Confirm"
                            : "Add"))
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
    // await AlertDialogs.showContentTextFieldDialog(
    //   context,
    //   barrierDismissible: true,
    //   blurBackground: false,
    //   message: "Add a New Member",
    //   validation: (arg) {
    //     if (arg == null || arg.trim().isEmpty) return "Empty username";
    //     return Validators.validateUsername(arg) ? null : "Invalid username";
    //   },
    //   content: (fieldValue, validateValue) {
    //     return StatefulBuilder(builder: (context, setState) {
    //       return Column(
    //         children: [
    //           ConstrainedBox(
    //             constraints: const BoxConstraints(maxHeight: 100),
    //             child: SingleChildScrollView(
    //               child: Wrap(
    //                 children: usernames
    //                     .map((e) => AppButton(
    //                         width: null,
    //                         size: AppButtonSize.small,
    //                         style: AppButtonStyle.outlined,
    //                         onPressed: () {},
    //                         child: Row(
    //                           mainAxisSize: MainAxisSize.min,
    //                           children: [
    //                             Text(e),
    //                             GestureDetector(
    //                               onTap: () {
    //                                 setState(() {
    //                                   Logger().d(e);
    //                                   usernames.remove(e);
    //                                 });
    //                               },
    //                               child: const Icon(
    //                                 Icons.close,
    //                                 size: 16,
    //                               ),
    //                             )
    //                           ],
    //                         )))
    //                     .toList(),
    //               ),
    //             ),
    //           ),
    //           if (usernames.isNotEmpty)
    //             const SizedBox(
    //               height: 24,
    //             ),
    //           AppButton(
    //               size: AppButtonSize.small,
    //               style: AppButtonStyle.filled,
    //               intent: AppButtonIntent.primary,
    //               onPressed: () {
    //                 Logger().d(validateValue());
    //                 if (validateValue()) {
    //                   setState(() {
    //                     usernames.add(fieldValue());
    //                   });
    //                 }
    //               },
    //               child: const Text("Add"))
    //         ],
    //       );
    //     });
    //   },
    // );

    // while (true) {
    //   String? username = await AlertDialogs.showTextFieldDialog(
    //     context,
    //     defaultHintText: AppLocalizations.of(context).signUpPage_Username_Field,
    //     barrierDismissible: true,
    //     blurBackground: false,
    //     message: "Add a New Member",
    //     label: AppLocalizations.of(context).signUpPage_Username,
    //     content: ConstrainedBox(
    //       constraints: const BoxConstraints(maxHeight: 100),
    //       child: SingleChildScrollView(
    //         child: Wrap(
    //           children: usernames
    //               .map((e) => AppButton(
    //                   width: null,
    //                   size: AppButtonSize.small,
    //                   style: AppButtonStyle.outlined,
    //                   onPressed: () {},
    //                   child: Row(
    //                     children: [
    //                       Text(e),
    //                       GestureDetector(
    //                         onTap: () {
    //                           usernames.remove(e);
    //                           // Navigator.of(context).pop();
    //                         },
    //                         child: const Icon(
    //                           Icons.close,
    //                           size: 16,
    //                         ),
    //                       )
    //                     ],
    //                   )))
    //               .toList(),
    //         ),
    //       ),
    //     ),
    //     validation: (p0) {
    //       if (p0 == null || p0.trim().isEmpty) return "Empty Username";
    //       return Validators.validateUsername(p0.trim())
    //           ? null
    //           : "Invalid Username";
    //     },
    //   );

    //   if (username != null) {
    //     usernames.add(username.trim());
    //   } else {
    //     break;
    //   }
    // }
  }

  static Future<String?> removeUserFromGroupPopup(
      BuildContext context, String username) async {
    return AlertDialogs.showTextFieldDialog(context,
        barrierDismissible: true,
        blurBackground: false,
        message: "Are you sure you want to remove user from group?",
        validation: (p0) {
      if (p0 == null || p0.trim().isEmpty) return "Empty Username";
      return Validators.validateUsername(p0.trim()) ? null : "Invalid Username";
    });
  }

  static Future<String?> createTaskPopup(BuildContext context) async {
    return AlertDialogs.showTextFieldDialog(context,
        barrierDismissible: true,
        blurBackground: false,
        defaultHintText: "Enter the title",
        label: "Task Title",
        message: "Add a New Task", validation: (p0) {
      if (p0 == null || p0.trim().isEmpty) return "Empty task title";

      return Validators.validateGroupTitle(p0) ? null : "Invalid task title";
    });
  }

  static Future<({String title, String description})?> createGroupPopup(
      BuildContext context) async {
    String? title;
    String? description;

    // TITLE POPUP
    title = await AlertDialogs.showTextFieldDialog(context,
        barrierDismissible: true,
        blurBackground: false,
        message: "New Group title", validation: (p0) {
      if (p0 == null || p0.trim().isEmpty) return "Empty title";
      return Validators.validateGroupTitle(p0) ? null : "Invalid title";
    });

    // DESCRIPTION POPUP
    if (title != null && context.mounted) {
      description = await AlertDialogs.showTextFieldDialog(context,
          barrierDismissible: true,
          blurBackground: false,
          message: "New Group description", validation: (p0) {
        if (p0 == null || p0.trim().isEmpty) return "Empty description";
        return Validators.validateGroupDescription(p0)
            ? null
            : "Invalid description";
      });
    }
    if (title == null || description == null) return null;
    return (title: title, description: description);
  }
}

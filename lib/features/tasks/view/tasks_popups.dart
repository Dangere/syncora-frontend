import 'dart:math';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/common/themes/app_sizes.dart';
import 'package:syncora_frontend/common/themes/app_theme.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/input_field.dart';
import 'package:syncora_frontend/common/widgets/profile_picture.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/core/utils/alert_dialogs.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';
import 'package:syncora_frontend/features/tasks/view/widgets/task_search_bar.dart';

class TasksPopups {
  // static void assignUsersPopUp(BuildContext context,
  //     {required Task task,
  //     required List<User> members,
  //     required Func<List<int>, void> onAssign,
  //     required bool isOwner}) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       // Removing the owner
  //       List<User> membersExcludingOwner =
  //           List<User>.from(members).where((element) {
  //         if (isOwner) {
  //           return element.id != members[0].id;
  //         } else {
  //           return task.assignedTo.contains(element.id);
  //         }
  //       }).toList();

  //       List<int> currentAssignees = membersExcludingOwner
  //           .where((element) => task.assignedTo.contains(element.id))
  //           .map((e) => e.id)
  //           .toList();
  //       return AlertDialog(
  //         title: Text(
  //           "Assigned users",
  //           style: Theme.of(context).textTheme.titleMedium,
  //         ),

  //         content: StatefulBuilder(builder: (context, setState) {
  //           return Container(
  //             height: 50,
  //             width: 400,
  //             decoration: BoxDecoration(
  //                 color: Colors.grey[50],
  //                 borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
  //             child: ListView.builder(
  //               scrollDirection: Axis.horizontal,
  //               itemCount: membersExcludingOwner.length,
  //               itemBuilder: (context, index) => Padding(
  //                 padding: const EdgeInsets.all(4.0),
  //                 child: Container(
  //                   // padding: const EdgeInsets.all(8.0),
  //                   decoration: BoxDecoration(
  //                       color: membersExcludingOwner[index].userColor(),
  //                       borderRadius:
  //                           BorderRadius.circular(AppSizes.borderRadius)),
  //                   height: 40,
  //                   child: Row(mainAxisSize: MainAxisSize.min, children: [
  //                     Padding(
  //                       padding: const EdgeInsets.symmetric(horizontal: 4.0) +
  //                           const EdgeInsets.only(left: 8.0),
  //                       child: Text(membersExcludingOwner[index].username),
  //                     ),
  //                     // We are excluding the owner from the list
  //                     Checkbox(
  //                         value: currentAssignees
  //                             .contains(membersExcludingOwner[index].id),
  //                         onChanged: (bool? value) {
  //                           if (!isOwner) return;
  //                           setState(() {});
  //                           if (value!) {
  //                             currentAssignees
  //                                 .add(membersExcludingOwner[index].id);
  //                           } else {
  //                             currentAssignees
  //                                 .remove(membersExcludingOwner[index].id);
  //                           }
  //                         })
  //                   ]),
  //                 ),
  //               ),
  //             ),
  //           );
  //         }),
  //         actionsAlignment: MainAxisAlignment.spaceBetween,
  //         // actionsOverflowAlignment: OverflowBarAlignment.center,
  //         actionsPadding: const EdgeInsets.all(15),
  //         actions: [
  //           ElevatedButton(
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //               },
  //               child: const Text("Cancel")),
  //           if (isOwner)
  //             ElevatedButton(
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                   onAssign(currentAssignees);
  //                 },
  //                 child: const Text("Assign users"))
  //         ],
  //       );
  //     },
  //   );
  // }

  // Shows a pop up containing all the members and allow the owner to select/unselect users to be assigned
  static Future<List<int>> assignedUsersPopUp(
    BuildContext context, {
    required Task task,
    required Future<List<User>> Function() groupMembers,
  }) async {
    List<User> members = await groupMembers();

    List<User> selectedUsers = members.where(
      (u) {
        return task.assignedTo.contains(u.id);
      },
    ).toList();

    void onUserToggle(int userId, void Function(void Function()) setState) {
      Logger().d(userId);
      bool isSelected =
          selectedUsers.where((user) => user.id == userId).isNotEmpty;

      setState(() {
        if (!isSelected) {
          selectedUsers.add(members.firstWhere((user) => user.id == userId));
        } else {
          selectedUsers.removeWhere((user) => user.id == userId);
        }
      });
    }

    void onConfirmSelection() {
      Navigator.of(context).pop();
    }

    void onSearch(String text, void Function(void Function()) setState) async {
      if (text.isNotEmpty) {
        members = await groupMembers();
        members =
            members.where((user) => user.username.contains(text)).toList();
      } else {
        members = await groupMembers();
      }
      setState(() {});
    }

    if (!context.mounted) return [];
    await AlertDialogs.showContentDialog(context,
        barrierDismissible: true,
        blurBackground: false,
        title: "Assigned users",
        content: StatefulBuilder(builder: (context, setState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // SEARCH BAR
          TasksSearchBar(
            onSearch: (query) => onSearch(query, setState),
          ),
          const SizedBox(
            height: 24,
          ),

          // ASSIGNED USERS
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 100),
            child: SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.start,
                spacing: 12,
                runSpacing: 10,
                children: members.map((member) {
                  bool selected = selectedUsers
                      .where((user) => user.id == member.id)
                      .isNotEmpty;
                  return GestureDetector(
                    onTap: () => onUserToggle(member.id, setState),
                    child: Container(
                      height: 35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          width: 0.8,
                          color: Theme.of(context)
                              .colorScheme
                              .scrim
                              .withValues(alpha: 0.4),
                        ),
                        color: selected
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.surfaceContainer,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: ProfilePicture(
                              userId: member.id,
                              imageUrl: member.pfpURL,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            member.username,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (members.isNotEmpty)
            const SizedBox(
              height: 24,
            ),
          // CONFIRM
          AppButton(
              size: AppButtonSize.small,
              style: AppButtonStyle.filled,
              intent: AppButtonIntent.primary,
              fontSize: 20,
              onPressed: () => onConfirmSelection(),
              child: Text("Confirm"))
        ],
      );
    }));

    return selectedUsers.map((e) => e.id).toList();
  }
}

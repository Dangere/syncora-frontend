import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/profile_picture.dart';
import 'package:syncora_frontend/core/utils/dialogs.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';
import 'package:syncora_frontend/features/tasks/view/widgets/task_search_bar.dart';

class TasksPopups {
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
    await Dialogs.showContentDialog(context,
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
            child: Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    spacing: 5,
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
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainer,
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

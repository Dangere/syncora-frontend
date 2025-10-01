import 'package:flutter/material.dart';
import 'package:syncora_frontend/common/themes/app_sizes.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';

class TaskAssignUsersPopup {
  static void assignUsersPopUp(BuildContext context,
      {required Task task,
      required List<User> members,
      required Func<List<int>, void> onAssign,
      required bool isOwner}) {
    showDialog(
      context: context,
      builder: (context) {
        // Removing the owner
        List<User> membersExcludingOwner =
            List<User>.from(members).where((element) {
          if (isOwner) {
            return element.id != members[0].id;
          } else {
            return task.assignedTo.contains(element.id);
          }
        }).toList();

        List<int> currentAssignees = membersExcludingOwner
            .where((element) => task.assignedTo.contains(element.id))
            .map((e) => e.id)
            .toList();
        return AlertDialog(
          title: Text(
            "Assigned users",
            style: Theme.of(context).textTheme.titleMedium,
          ),

          content: StatefulBuilder(builder: (context, setState) {
            return Container(
              height: 50,
              width: 400,
              decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: membersExcludingOwner.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Container(
                    // padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                        color: membersExcludingOwner[index].userColor(),
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadius)),
                    height: 40,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0) +
                            const EdgeInsets.only(left: 8.0),
                        child: Text(membersExcludingOwner[index].username),
                      ),
                      // We are excluding the owner from the list
                      Checkbox(
                          value: currentAssignees
                              .contains(membersExcludingOwner[index].id),
                          onChanged: (bool? value) {
                            if (!isOwner) return;
                            setState(() {});
                            if (value!) {
                              currentAssignees
                                  .add(membersExcludingOwner[index].id);
                            } else {
                              currentAssignees
                                  .remove(membersExcludingOwner[index].id);
                            }
                          })
                    ]),
                  ),
                ),
              ),
            );
          }),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          // actionsOverflowAlignment: OverflowBarAlignment.center,
          actionsPadding: const EdgeInsets.all(15),
          actions: [
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Cancel")),
            if (isOwner)
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAssign(currentAssignees);
                  },
                  child: const Text("Assign users"))
          ],
        );
      },
    );
  }
}

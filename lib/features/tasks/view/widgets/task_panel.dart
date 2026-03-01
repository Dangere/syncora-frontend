import 'package:flutter/material.dart';
import 'package:syncora_frontend/common/widgets/profile_picture.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/features/groups/view/widgets/compressed_members_display.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';

class TaskPanel extends StatelessWidget {
  const TaskPanel(
      {super.key,
      required this.task,
      required this.isCompleted,
      required this.onDelete,
      required this.onChange,
      required this.onTap,
      required this.assignedUsers,
      required this.isOwner});
  final Task task;
  final VoidCallback onDelete;
  final Func<bool?, void> onChange;
  final VoidCallback onTap;
  final List<int> assignedUsers;
  final bool isOwner;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: 50,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.title + ("(${task.id.toString()})")),
                      ],
                    ),
                  ),

                  CompressedMembersDisplay(
                    memberIds: assignedUsers,
                    spacing: 25,
                    radius: 20,
                  ),

                  // Expanded(
                  //     child: ListView.builder(
                  //   itemCount: assignedUsers.length,
                  //   itemBuilder: (context, index) {
                  //     return ProfilePicture(
                  //         userId: assignedUsers[index], radius: 20);
                  //   },
                  // ))
                  // Row(
                  //   children: [
                  //     if (isOwner)
                  //       IconButton(
                  //           onPressed: onDelete,
                  //           icon: const Icon(Icons.delete)),
                  //     Checkbox(
                  //       value: isCompleted,
                  //       onChanged: onChange,
                  //     )
                  //   ],
                  // )
                ]),
          ),
        ),
      ),
    );
  }
}

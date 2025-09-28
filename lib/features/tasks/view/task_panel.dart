import 'package:flutter/material.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';

class TaskPanel extends StatelessWidget {
  const TaskPanel(
      {super.key,
      required this.task,
      required this.onDelete,
      required this.onChange,
      required this.onTap,
      required this.userColors});
  final Task task;
  final VoidCallback onDelete;
  final Func<bool?, void> onChange;
  final VoidCallback onTap;
  final List<Color> userColors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(task.title),
              Row(
                children: [
                  IconButton(
                      onPressed: onDelete, icon: const Icon(Icons.delete)),
                  Checkbox(
                    value: task.completedById != null,
                    onChanged: onChange,
                  )
                ],
              )
            ]),
            Row(children: [
              for (int i = 0; i < task.assignedTo.length; i++)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: userColors[i],
                    ),
                  ),
                )
            ])
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';

class TaskPanel extends StatelessWidget {
  const TaskPanel(
      {super.key,
      required this.task,
      required this.onDelete,
      required this.onChange,
      required this.onTap});
  final Task task;
  final VoidCallback onDelete;
  final Func<bool?, void> onChange;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(task.title),
            Row(
              children: [
                IconButton(onPressed: onDelete, icon: const Icon(Icons.delete)),
                Checkbox(
                  value: task.completedById != null,
                  onChanged: onChange,
                )
              ],
            )
          ]),
        ),
      ),
    );
  }
}

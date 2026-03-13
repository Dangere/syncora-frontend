import 'package:flutter/material.dart';
import 'package:syncora_frontend/common/themes/app_theme.dart';
import 'package:syncora_frontend/common/widgets/marquee_widget.dart';
import 'package:syncora_frontend/features/groups/view/widgets/compressed_members_display.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';

class TaskPanel extends StatelessWidget {
  const TaskPanel(
      {super.key,
      required this.task,
      required this.isCompleted,
      required this.onDelete,
      required this.onTap,
      required this.onHold,
      required this.assignedUsers,
      required this.isOwner});
  final Task task;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onHold;
  final List<int> assignedUsers;
  final bool isOwner;
  final bool isCompleted;

  Widget _body(BuildContext context) => GestureDetector(
        onTap: onTap,
        onLongPress: onHold,
        child: SizedBox(
          // height: 66,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            decoration: BoxDecoration(
              boxShadow: [AppShadow.shadow0(context)],
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              _CheckButton(value: isCompleted),
              const SizedBox(
                width: 13,
              ),
              Expanded(
                  child: MarqueeWidget(
                direction: Axis.vertical,
                child: Text(
                  // maxLines: 2,
                  task.title,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                      decorationThickness: 1, // Set the desired thickness
                      decorationColor:
                          Theme.of(context).colorScheme.outline, // Optional
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.outline),
                ),
              )),
              CompressedMembersDisplay(
                memberIds: assignedUsers,
                spacing: 20,
                radius: 20,
              ),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return isOwner
        ? Dismissible(
            onDismissed: (direction) {
              onDelete();
            },
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                boxShadow: [AppShadow.shadow0(context)],
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                ],
              ),
            ),
            key: Key(task.id.toString()),
            child: _body(context),
          )
        : _body(context);
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(90.0),
        color: value
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        border: Border.all(
          color: value
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.scrim.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        child: !value
            ? null
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary),
                  child: Icon(
                    Icons.check_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
      ),
    );
  }
}

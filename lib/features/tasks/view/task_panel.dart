import 'dart:math';

import 'package:color_hash/color_hash.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:syncora_frontend/common/widgets/marquee_widget.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';

class TaskPanel extends StatelessWidget {
  const TaskPanel(
      {super.key,
      required this.task,
      required this.isCompleted,
      required this.onDelete,
      required this.onChange,
      required this.onTap,
      required this.userColors,
      required this.isOwner});
  final Task task;
  final VoidCallback onDelete;
  final Func<bool?, void> onChange;
  final VoidCallback onTap;
  final List<Color> userColors;
  final bool isOwner;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    // int randomInt = Random().nextInt(15);
    // userColors = List.generate(randomInt,
    //     (index) => ColorHash(index.toString() + task.id.toString()).toColor());

    List<Widget> userDots() {
      return List.generate(
          userColors.length,
          (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: userColors[index],
                  ),
                ),
              ));
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: 50,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
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
                        Text(task.title),
                        MarqueeWidget(
                          child: Row(
                            children: userDots(),
                          ),
                        )
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (isOwner)
                        IconButton(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete)),
                      Checkbox(
                        value: isCompleted,
                        onChanged: onChange,
                      )
                    ],
                  )
                ]),
          ),
        ),
      ),
    );
  }
}

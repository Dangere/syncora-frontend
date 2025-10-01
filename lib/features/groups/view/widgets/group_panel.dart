import 'package:flutter/material.dart';
import 'package:syncora_frontend/common/themes/app_sizes.dart';
import 'package:syncora_frontend/common/widgets/marquee_widget.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';

class GroupPanel extends StatelessWidget {
  final Group group;
  // TODO: Use this to display icons instead

  const GroupPanel({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: 170,
      child: Container(
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(1, 2), // changes position of shadow
              ),
            ],
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
        child: Column(
          children: [
            Center(
                child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 150, maxHeight: 20),
                    child: MarqueeWidget(
                      child: Text(
                        "${group.title} (${group.id})",
                      ),
                    )
                    // child: Text(
                    //   "${group.title} (${group.id})",
                    //   overflow: TextOverflow.fade,
                    // ),
                    )),
            const Divider(),
            // Maybe make it so if theres no members it shows the top tasks briefly
            Expanded(
                child: Wrap(
              clipBehavior: Clip.antiAlias,
              children: List.generate(
                  group.groupMembersIds.length > 10
                      ? 10
                      : group.groupMembersIds.length,
                  (index) => const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Icon(
                          Icons.person,
                          size: 28,
                        ),
                      )),
            ))
          ],
        ),
      ),
    );
  }
}

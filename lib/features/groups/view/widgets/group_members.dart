import 'package:flutter/material.dart';
import 'package:syncora_frontend/common/themes/app_sizes.dart';
import 'package:syncora_frontend/common/widgets/marquee_widget.dart';
import 'package:syncora_frontend/common/widgets/profile_picture.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';

class GroupMembers extends StatelessWidget {
  const GroupMembers(
      {super.key,
      required this.isOwner,
      required this.group,
      this.authState,
      required this.onAddUserButton,
      required this.members,
      required this.onMemberClick});

  final bool isOwner;
  final Group group;
  final AuthState? authState;
  final VoidCallback onAddUserButton;
  final List<User> members;
  final Func<int, void> onMemberClick;

  @override
  Widget build(BuildContext context) {
    String displayName(User user) {
      return user.username +
          ((user.id == authState?.user?.id) ? " (You)" : "") +
          ((user.id == group.ownerUserId) ? " (Owner)" : "");
    }

    Widget addMemberButton() => Padding(
          padding: const EdgeInsets.all(2.0),
          child: SizedBox(
            width: 50,
            height: 70,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.group_add_rounded,
                    color: Colors.grey,
                  ),
                  onPressed: onAddUserButton,
                )
              ],
            ),
          ),
        );

    List<Widget> membersWidgets(List<User> users) {
      return List.generate(
          users.length > 10 ? 10 : users.length,
          (index) => Padding(
                padding: const EdgeInsets.all(5.0),
                child: GestureDetector(
                  onTap: () => onMemberClick(users[index].id),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ProfilePicture(userId: users[index].id, radius: 25),
                        // SizedBox(
                        //   child: CircleAvatar(
                        //     radius: 25,
                        //     backgroundColor: users[index].userColor(),
                        //     child: const Icon(
                        //       Icons.person,
                        //     ),
                        //   ),
                        // ),
                        MarqueeWidget(
                          child: Text(displayName(users[index]),
                              style: Theme.of(context).textTheme.bodySmall),
                        )
                      ],
                    ),
                  ),
                ),
              ));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
            color: Colors.grey[50],
            // border: Border.all(),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                spreadRadius: 0,
                blurRadius: 5,
                offset: const Offset(0.5, 0.5),
              )
            ],
            borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                membersWidgets(members) + (isOwner ? [addMemberButton()] : []),
          ),
        ),
      ),
    );
  }
}

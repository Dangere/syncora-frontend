import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/widgets/profile_picture.dart';

class CompressedMembersDisplay extends StatelessWidget {
  const CompressedMembersDisplay({
    super.key,
    required this.memberIds,
    this.flipStackOrder = false,
    this.direction = AxisDirection.right,
    this.maxMembers = 3,
    this.ownerId,
    this.radius = 14,
    this.spacing = 8,
    this.fontSize = 14,
  });

  final int maxMembers;
  final bool flipStackOrder;
  final AxisDirection direction;
  final List<int> memberIds;
  final int? ownerId;
  final double radius;
  final double spacing;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (memberIds.isEmpty && ownerId == null) return Container();

    // Displayed members, is only between 1 and max members
    List<int> displayedMembers = memberIds.sublist(
        0, memberIds.length > maxMembers ? maxMembers : memberIds.length);

    if (ownerId != null && displayedMembers.length < maxMembers) {
      displayedMembers.add(ownerId!);
      displayedMembers = displayedMembers.reversed.toList();
    }

    int remainingMembersCount =
        memberIds.length + (ownerId != null ? 1 : 0) - displayedMembers.length;

    // Flip members if right to left, the row containing the stack and text also gets flipped on rtl/ltr
    bool flipOrder = flipStackOrder
        ? !(Directionality.of(context) == TextDirection.ltr)
        : (Directionality.of(context) == TextDirection.ltr);

    double width = (radius * 2) + (spacing * (displayedMembers.length - 1));

    List<Widget> membersWidgets() {
      return List<Widget>.of([
            SizedBox(
              width: width, // Total width including the overflow
              height: radius * 2,
            ),
          ]) +
          List<Widget>.generate(displayedMembers.length, (index) {
            return Positioned(
              right: spacing * index,
              child: ProfilePicture(
                  userId: displayedMembers[
                      flipOrder ? displayedMembers.length - 1 - index : index],
                  radius: radius),
            );
          });
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Consumer(builder: (context, ref, child) {
          return Stack(
              textDirection: TextDirection.ltr,
              clipBehavior: Clip.none,
              children: !flipOrder
                  ? membersWidgets()
                  : membersWidgets().reversed.toList());
        }),

        // Text if members over maxMembers
        if (remainingMembersCount > 0)
          Text(
            " +$remainingMembersCount",
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.scrim,
                  fontSize: fontSize,
                ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/widgets/profile_picture.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/view/widgets/compressed_members_display.dart';

class GroupMembersDisplay extends ConsumerWidget {
  const GroupMembersDisplay(
      {super.key,
      required this.group,
      required this.isOwner,
      required this.onAddingMember});

  final Group group;
  final bool isOwner;
  final VoidCallback onAddingMember;
  final double radius = 21.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 74,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: Theme.of(context).colorScheme.surfaceContainer,
                width:
                    Theme.of(context).brightness == Brightness.light ? 1.5 : 3),
            shape: BoxShape.rectangle,
            color: Theme.of(context)
                .colorScheme
                .surfaceContainer
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 13,
              ),
              // Group owner is always first
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ProfilePicture(
                    userId: group.ownerUserId,
                    radius: radius,
                    onClick: () {
                      context.pushNamed("profile-view",
                          pathParameters: {"id": group.ownerUserId.toString()});
                    },
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    AppLocalizations.of(context).owner.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600),
                  )
                ],
              ),
              const SizedBox(
                width: 5,
              ),
              VerticalDivider(
                indent: 14,
                endIndent: 14,
                thickness: 1.5,
                color: Theme.of(context).colorScheme.surfaceContainer,
                // width: 1.5,
              ),

              // Compressed members
              Expanded(
                child: CompressedMembersDisplay(
                  fontSize: 18,
                  flipStackOrder: true,
                  memberIds: group.groupMembersIds,
                  direction: AxisDirection.left,
                  // ownerId: group.ownerUserId,
                  radius: 21,
                  spacing: (21 * 2) - 12,
                  maxMembers: 5,
                ),
              ),
              // Add member
              if (isOwner)
                Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          width: 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                            onPressed: () {
                              onAddingMember();
                            },
                            icon: Icon(
                              Icons.person_add_alt_1,
                              color: Theme.of(context).colorScheme.onPrimary,
                            )),
                      ],
                    ))
            ],
          ),
        ),
      ),
    );
  }
}

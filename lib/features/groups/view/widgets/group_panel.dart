import 'package:flutter/material.dart';
import 'package:syncora_frontend/common/themes/app_sizes.dart';
import 'package:syncora_frontend/common/themes/app_theme.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/view/widgets/compressed_members_display.dart';

class GroupPanel extends StatelessWidget {
  final Group group;
  final double memberIconsSpacing = 15;
  final double memberIconsRadius = 13;

  const GroupPanel({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        height: 126,
        decoration: BoxDecoration(
          boxShadow: [AppShadow.shadow0(context)],
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.title,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              "${group.description}",
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  height: 1.2,
                  color: Theme.of(context).colorScheme.outlineVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Expanded(child: Container()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // TASKS COUNT
                Row(
                  children: [
                    Icon(
                      Icons.my_library_books_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${group.tasksIds.length}",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      " ${AppLocalizations.of(context).tasks}",
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  ],
                ),
                // MEMBERS DISPLAY
                Container(
                  color: Colors.red,
                  child: CompressedMembersDisplay(
                    memberIds: group.groupMembersIds,
                    ownerId: group.ownerUserId,
                    radius: memberIconsRadius,
                    spacing: memberIconsSpacing,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

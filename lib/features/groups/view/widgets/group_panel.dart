import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/web.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_sizes.dart';
import 'package:syncora_frontend/common/themes/app_theme.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/users/viewmodel/users_providers.dart';

class GroupPanel extends StatelessWidget {
  final Group group;
  final double memberIconsSpacing = 15;
  final double memberIconsRadius = 13;

  const GroupPanel({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    // Logger().w("Building group panel for group ${group.id}");
    Widget profilePicture(WidgetRef ref, int id) {
      return FutureBuilder(
        future: ref.read(usersServiceProvider).getUserProfilePicture(id),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isSuccess) {
              // if we have no image
              if (snapshot.data!.data == null) {
                return const Icon(
                  Icons.person,
                );
              }
              // if we have an image
              return Image.memory(snapshot.data!.data!);
            } else {
              // if we have an error
              ref.read(loggerProvider).e(snapshot.data!.error!.message);
              ref.read(loggerProvider).e(snapshot.data!.error!.stackTrace);

              return const Icon(
                Icons.error,
              );
            }
          } else {
            // if we are still loading
            return const CircularProgressIndicator();
          }
        },
      );
    }

    // Members, and owner if less than 3
    Widget membersDisplay() {
      // Displayed members, is only between 1 and 3
      List<int> displayedMembers = group.groupMembersIds.sublist(0,
          group.groupMembersIds.length > 3 ? 3 : group.groupMembersIds.length);
      if (displayedMembers.length < 3) {
        displayedMembers.add(group.ownerUserId);
        displayedMembers = displayedMembers.reversed.toList();
      }
      bool flipMembers = Directionality.of(context) == TextDirection.rtl;
      return Row(
        children: [
          Consumer(builder: (context, ref, child) {
            return Stack(
              textDirection: TextDirection.ltr,
              clipBehavior: Clip.none,
              children: [
                if (displayedMembers.length > 2)
                  Positioned(
                    right: memberIconsSpacing * 2 * (flipMembers ? -1 : 1),
                    child: CircleAvatar(
                      backgroundColor:
                          Random().nextBool() ? Colors.cyan : Colors.yellow,
                      radius: memberIconsRadius,
                      child: profilePicture(ref, displayedMembers[2]),
                    ),
                  ),
                if (displayedMembers.length > 1)
                  Positioned(
                    right: memberIconsSpacing * (flipMembers ? -1 : 1),
                    child: CircleAvatar(
                      backgroundColor:
                          Random().nextBool() ? Colors.red : Colors.green,
                      radius: memberIconsRadius,
                      child: profilePicture(ref, displayedMembers[1]),
                    ),
                  ),
                CircleAvatar(
                  radius: memberIconsRadius,
                  child: profilePicture(ref, displayedMembers[0]),
                ),
              ],
            );
          }),

          // Text if members over 3
          if (displayedMembers.length > 3)
            Text(
              " +${group.groupMembersIds.length - 2}",
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.scrim,
                  ),
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        height: 126,
        decoration: BoxDecoration(
          boxShadow: [AppShadow.shadow0(context)],
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${group.title}",
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
                membersDisplay(),
              ],
            )
          ],
        ),
      ),
    );
    // return SizedBox(
    //   height: 100,
    //   width: 170,
    //   child: Container(
    //     decoration: BoxDecoration(
    //         boxShadow: [
    //           BoxShadow(
    //             color: Colors.grey.withOpacity(0.5),
    //             spreadRadius: 1,
    //             blurRadius: 2,
    //             offset: const Offset(1, 2), // changes position of shadow
    //           ),
    //         ],
    //         color: Colors.grey[200],
    //         borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
    //     child: Column(
    //       children: [
    //         Center(
    //             child: ConstrainedBox(
    //                 constraints:
    //                     const BoxConstraints(maxWidth: 150, maxHeight: 20),
    //                 child: MarqueeWidget(
    //                   child: Text(
    //                     "${group.title} (${group.id})",
    //                   ),
    //                 )
    //                 // child: Text(
    //                 //   "${group.title} (${group.id})",
    //                 //   overflow: TextOverflow.fade,
    //                 // ),
    //                 )),
    //         const Divider(),
    //         // Maybe make it so if theres no members it shows the top tasks briefly
    //         Expanded(
    //             child: Wrap(
    //           clipBehavior: Clip.antiAlias,
    //           children: List.generate(
    //               group.groupMembersIds.length > 10
    //                   ? 10
    //                   : group.groupMembersIds.length,
    //               (index) => const Padding(
    //                     padding: EdgeInsets.all(2.0),
    //                     child: Icon(
    //                       Icons.person,
    //                       size: 28,
    //                     ),
    //                   )),
    //         ))
    //       ],
    //     ),
    //   ),
    // );
  }
}

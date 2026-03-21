import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_theme.dart';
import 'package:syncora_frontend/common/widgets/progress_bar.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/features/groups/groups_provider.dart';
import 'package:syncora_frontend/features/groups/models/group_progress.dart';

class GroupTotalProgressCard extends ConsumerStatefulWidget {
  const GroupTotalProgressCard({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _GroupTotalProgressCardState();
}

class _GroupTotalProgressCardState
    extends ConsumerState<GroupTotalProgressCard> {
  GroupProgress? groupProgress;

  double tempProgress = 0;

  @override
  Widget build(BuildContext context) {
    ref.watch(groupsProvider.select((groupState) {
      return groupState.value;
    }));
    return FutureBuilder(
        future:
            ref.read(groupsProvider.notifier).getGroupsTotalProgress(true, 30),
        builder: (context, asyncSnapshot) {
          if (asyncSnapshot.connectionState == ConnectionState.waiting &&
              groupProgress == null) {
            return const Center(child: CircularProgressIndicator());
          }

          groupProgress = asyncSnapshot.data;

          if (groupProgress == null) return Container();

          ref.read(loggerProvider).d(groupProgress.toString());

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            width: double.infinity,
            decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    width: 3, color: Theme.of(context).colorScheme.surface)),
            child: Column(
              children: [
                const SizedBox(
                  height: 18,
                ),
                // TITLE AND EXPAND BUTTON
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // TITLE
                    Text(
                      "Your Monthly Progress",
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    // EXPAND BUTTON
                    IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => context.push('/groups-progress'),
                        icon: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surface, // The background color of the circle
                            shape: BoxShape.circle,
                            boxShadow: [
                              AppShadow.shadow0(context),
                              AppShadow.shadow0(context)
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_forward_outlined,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ))
                  ],
                ),
                const SizedBox(
                  height: 21,
                ),

                ProgressBar(
                  percentage: groupProgress!.percentage,
                  gradient: false,
                ),

                const SizedBox(
                  height: 35,
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.playlist_add_check_circle_outlined,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 23,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        RichText(
                          text: TextSpan(
                            text:
                                "${groupProgress!.completedTasks.toString()} ",
                            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant), // Default style for the parent
                            children: <TextSpan>[
                              TextSpan(
                                  text: AppLocalizations.of(context)
                                      .filter_Completed,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 10,
                        ),
                        Icon(
                          Icons.hourglass_bottom_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 23,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        RichText(
                          text: TextSpan(
                            text:
                                "${groupProgress!.incompleteTasks.toString()} ",
                            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant), // Default style for the parent
                            children: <TextSpan>[
                              TextSpan(
                                  text: AppLocalizations.of(context)
                                      .filter_InProgress,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          );
        });
  }
}

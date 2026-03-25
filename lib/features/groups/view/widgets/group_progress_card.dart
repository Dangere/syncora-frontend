import 'package:flutter/material.dart';
import 'package:syncora_frontend/common/themes/app_theme.dart';
import 'package:syncora_frontend/common/widgets/marquee_widget.dart';
import 'package:syncora_frontend/common/widgets/progress_bar.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/features/groups/models/group_progress.dart';

enum GroupProgressCardStyle {
  dashboard,
  menu,
}

class GroupProgressCard extends StatelessWidget {
  const GroupProgressCard({
    super.key,
    required this.groupProgress,
    required this.onExpand,
    this.style = GroupProgressCardStyle.dashboard,
  });

  final GroupProgress groupProgress;
  final VoidCallback onExpand;
  final GroupProgressCardStyle style;

  BoxDecoration _boxDecoration(BuildContext context) =>
      style == GroupProgressCardStyle.dashboard
          ? BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainer
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  width: 3, color: Theme.of(context).colorScheme.surface))
          : BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [AppShadow.shadow0(context)]);

  TextStyle _titleStyle(BuildContext context) =>
      style == GroupProgressCardStyle.dashboard
          ? Theme.of(context).textTheme.titleSmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface)
          : Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.w600,
              );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      decoration: _boxDecoration(context),
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
              Expanded(
                child: MarqueeWidget(
                    child: Text(
                  groupProgress.groupTitle,
                  style: _titleStyle(context),
                )),
              ),
              const SizedBox(
                width: 10,
              ),
              // EXPAND BUTTON
              IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: onExpand,
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
            percentage: groupProgress.percentage,
            gradient: false,
          ),

          SizedBox(
            height: style == GroupProgressCardStyle.dashboard ? 35 : 20,
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Spacer(
                flex: 1,
              ),
              Row(
                children: [
                  Icon(
                    Icons.playlist_add_check_circle_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 23,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  RichText(
                    text: TextSpan(
                      text: "${groupProgress.completedTasks.toString()} ",
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant), // Default style for the parent
                      children: <TextSpan>[
                        TextSpan(
                            text: AppLocalizations.of(context).filter_Completed,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(
                flex: 4,
              ),
              Row(
                children: [
                  Icon(
                    Icons.hourglass_bottom_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 23,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  RichText(
                    text: TextSpan(
                      text: "${groupProgress.incompleteTasks.toString()} ",
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant), // Default style for the parent
                      children: <TextSpan>[
                        TextSpan(
                            text:
                                AppLocalizations.of(context).filter_InProgress,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(
                flex: 1,
              ),
            ],
          ),

          SizedBox(
            height: style == GroupProgressCardStyle.dashboard ? 30 : 25,
          ),
        ],
      ),
    );
  }
}

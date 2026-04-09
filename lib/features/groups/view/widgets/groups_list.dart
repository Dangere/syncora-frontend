import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/filter_list.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/view/widgets/group_panel.dart';
import 'package:syncora_frontend/features/groups/groups_provider.dart';

class GroupsList extends ConsumerWidget {
  const GroupsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: This builds 4 times even when not viewed..
    // it rebuilds 2 times if loading indicator is disabled
    ref.read(loggerProvider).d("Building groups list");
    List<Group> groups =
        ref.watch(groupsListProvider).valueOrNull ?? List.empty();
    // List<Group> groupsList = groups ? groups.value! : List.empty();

    return MultiSliver(
      children: [
        SliverClip(
          child: SliverStack(
            children: [
              // BACKGROUND BEHIND THE GROUPS
              SliverPositioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
              // GROUPS
              SliverPadding(
                padding: const EdgeInsets.only(
                    bottom: AppSpacing.lg, top: AppSpacing.md),
                sliver: SliverList.separated(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        context.push('/group/${groups[index].id}');
                      },
                      child: GroupPanel(
                        group: groups[index],
                      ),
                    );
                  },
                  separatorBuilder: (context, index) {
                    return const SizedBox(
                      height: 16,
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // BACKGROUND TO FILL ANY REMAINING SPACE UNDER THE GROUPS (when theres no groups or few that dont fill the entire space)
        SliverFillRemaining(
          fillOverscroll: false,
          hasScrollBody: false,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),
      ],
    );
    // return OverlayLoader(
    //   isLoading: false,
    //   body: ListView.separated(
    //     padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg / 2),
    //     itemCount: groups.length,
    //     itemBuilder: (context, index) {
    //       return GestureDetector(
    //         onTap: () {
    //           context.push('/group/${groups[index].id}');
    //         },
    //         child: GroupPanel(
    //           group: groups[index],
    //         ),
    //       );
    //     },
    //     separatorBuilder: (context, index) {
    //       return const SizedBox(
    //         height: 16,
    //       );
    //     },
    //   ),
    // );
  }
}

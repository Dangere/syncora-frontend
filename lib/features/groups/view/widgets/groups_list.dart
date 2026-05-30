import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/view/widgets/group_panel.dart';
import 'package:syncora_frontend/features/groups/groups_provider.dart';

/// Displays a list of groups in a sliver
class GroupsList extends ConsumerWidget {
  const GroupsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(loggerProvider).d("Building groups list");
    List<Group> groups =
        ref.watch(groupsListProvider).valueOrNull ?? List.empty();
    // List<Group> groupsList = groups ? groups.value! : List.empty();
    ref.watch(groupsListProvider);
    return SliverClip(
      child: DecoratedSliver(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        sliver: MultiSliver(children: [
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
          SliverFillRemaining(
            hasScrollBody: false,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          )
        ]),
      ),
    );
  }
}

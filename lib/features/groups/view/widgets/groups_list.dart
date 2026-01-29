import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/filter_list.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/view/widgets/group_panel.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';

class GroupsList extends ConsumerWidget {
  const GroupsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var groups = ref.watch(groupsNotifierProvider);
    List<Group> groupsList = groups.hasValue ? groups.value! : List.empty();
    return Expanded(
      child: Column(
        children: [
          // FILTER
          FilterList<GroupsFilter>(
            multiSelect: true,
            disable: groups.isLoading,
            initialValue: ref.read(groupsNotifierProvider.notifier).filters,
            items: [
              FilterListItem(
                title: "Completed",
                value: GroupsFilter.completed,
                opposites: [GroupsFilter.inProgress],
                countFactory: (arg) => ref
                    .read(groupsNotifierProvider.notifier)
                    .getGroupsCount([arg]),
              ),
              FilterListItem(
                title: "In Progress",
                value: GroupsFilter.inProgress,
                opposites: [GroupsFilter.completed],
                countFactory: (arg) => ref
                    .read(groupsNotifierProvider.notifier)
                    .getGroupsCount([arg]),
              ),
              FilterListItem(
                title: "Owned",
                value: GroupsFilter.owned,
                opposites: [GroupsFilter.shared],
              ),
              FilterListItem(
                title: "Shared",
                value: GroupsFilter.shared,
                opposites: [GroupsFilter.owned],
              ),
              FilterListItem(
                title: "Newest",
                value: GroupsFilter.newest,
                opposites: [GroupsFilter.oldest],
              ),
              FilterListItem(
                title: "Oldest",
                value: GroupsFilter.oldest,
                opposites: [GroupsFilter.newest],
              ),
            ],
            onTap: (arg) {
              ref.read(groupsNotifierProvider.notifier).filterGroups(arg);
            },
          ),
          const SizedBox(height: AppSpacing.lg / 2),

          Expanded(
              child: OverlayLoader(
            isLoading: groups.isLoading,
            body: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg / 2),
              itemCount: groupsList.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    context.push('/group-view/${groupsList[index].id}');
                  },
                  child: GroupPanel(
                    group: groupsList[index],
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return const SizedBox(
                  height: 16,
                );
              },
            ),
          )),
        ],
      ),
    );
  }
}

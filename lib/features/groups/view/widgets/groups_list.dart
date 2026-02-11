import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/filter_list.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/view/widgets/group_panel.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';

class GroupsList extends ConsumerWidget {
  const GroupsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: This builds 4 times even when not viewed..
    // it rebuilds 2 times if loading indicator is disabled
    ref.read(loggerProvider).d("Building groups list");
    List<Group> groups =
        ref.watch(groupsNotifierProvider.select((state) => state.value)) ??
            List.empty();
    // List<Group> groupsList = groups ? groups.value! : List.empty();
    return Expanded(
      child: Column(
        children: [
          // FILTER
          FilterList<GroupsFilter>(
            multiSelect: true,
            disable: false,
            initialValue: ref.read(groupsNotifierProvider.notifier).filters,
            items: [
              FilterListItem(
                title: AppLocalizations.of(context).filter_Completed,
                value: GroupsFilter.completed,
                opposites: [GroupsFilter.inProgress],
                countFactory: (arg) => ref
                    .read(groupsNotifierProvider.notifier)
                    .getGroupsCount([arg]),
              ),
              FilterListItem(
                title: AppLocalizations.of(context).filter_InProgress,
                value: GroupsFilter.inProgress,
                opposites: [GroupsFilter.completed],
                countFactory: (arg) => ref
                    .read(groupsNotifierProvider.notifier)
                    .getGroupsCount([arg]),
              ),
              FilterListItem(
                title: AppLocalizations.of(context).filter_Owned,
                value: GroupsFilter.owned,
                opposites: [GroupsFilter.shared],
              ),
              FilterListItem(
                title: AppLocalizations.of(context).filter_Shared,
                value: GroupsFilter.shared,
                opposites: [GroupsFilter.owned],
              ),
              FilterListItem(
                title: AppLocalizations.of(context).filter_Newest,
                value: GroupsFilter.newest,
                opposites: [GroupsFilter.oldest],
              ),
              FilterListItem(
                title: AppLocalizations.of(context).filter_Oldest,
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
            isLoading: false,
            body: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg / 2),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    context.push('/group-view/${groups[index].id}');
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
          )),
        ],
      ),
    );
  }
}

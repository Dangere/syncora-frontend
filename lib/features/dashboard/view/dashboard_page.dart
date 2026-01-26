import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/filter_list.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/core/data/enums/database_tables.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/tests.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/view/widgets/group_panel.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    // We assume that the user is logged in and there's always a user provided if we are on this page
    // User user = ref.read(authNotifierProvider).value!.user!;
    SnackBarAlerts.registerErrorListener(ref, context);

    ref.read(loggerProvider).d("Building dashboard page");
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Tests.test_group_query(ref);
        },
      ),
      body: Stack(
        children: [
          // BACKGROUND GRAPHIC COLORS
          Positioned.fill(
            child: SvgPicture.asset(
                width: double.infinity,
                // height: 371,
                // fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                fit: BoxFit.fitWidth,
                "assets/images/background_dashboard_effect.svg"),
          ),
          // BACKGROUND GRAPHIC

          Positioned.fill(
            child: SvgPicture.asset(
                width: double.infinity,
                // height: 371,
                // fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                fit: BoxFit.fitWidth,
                "assets/images/background_dashboard.svg"),
          ),

          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Padding(
                  padding: AppSpacing.paddingHorizontalLg,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(
                        width: 90,
                        height: 38,
                        child: Icon(
                          Icons.logo_dev_outlined,
                          size: 40,
                        ),
                      ),
                      Container(
                        width: 110,
                        height: 55,
                        decoration: ShapeDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainer
                              .withValues(alpha: 0.45),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                                width: 3,
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainer),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox.square(
                                dimension: 48,
                                child: Padding(
                                  padding: const EdgeInsets.all(2.3),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainer,
                                        shape: BoxShape.circle),
                                    child: IconButton(
                                      padding: const EdgeInsets.all(0),
                                      onPressed: () =>
                                          context.pushNamed("settings"),
                                      icon: Icon(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        Icons.settings_outlined,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                )),
                            SizedBox.square(
                                dimension: 48,
                                child: Padding(
                                  padding: const EdgeInsets.all(2.3),
                                  child: Container(
                                      decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          shape: BoxShape.circle),
                                      child:
                                          const Icon(Icons.person, size: 30)),
                                ))
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // GROUPS

                Expanded(
                  child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(40.0),
                            topRight: Radius.circular(40.0)),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: AppSpacing.lg),
                          // CREATE GROUP BUTTON
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AppButton(
                                  width: 150,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg),
                                  // variant: AppButtonVariant.wide,
                                  onPressed: () {},
                                  size: AppButtonSize.small,
                                  style: AppButtonStyle.filled,
                                  intent: AppButtonIntent.primary,
                                  fontSize: 16,
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Icon(Icons.add),
                                      Text(
                                        "Create Group",
                                      ),
                                    ],
                                  )),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // GROUPS LIST AND FILTER
                          const GroupsList(),
                        ],
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
          FilterList(
            multiSelect: true,
            disable: groups.isLoading,
            items: [
              FilterListItem(
                title: "Completed",
                value: GroupsFilter.completed,
                opposites: [GroupsFilter.inProgress],
              ),
              FilterListItem(
                title: "In Progress",
                value: GroupsFilter.inProgress,
                opposites: [GroupsFilter.completed],
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
            onTap: (List<Enum> arg) {
              ref
                  .read(groupsNotifierProvider.notifier)
                  .filterGroups(arg.map((e) => e as GroupsFilter).toList());
            },
          ),
          Expanded(
              child: OverlayLoader(
            isLoading: groups.isLoading,
            body: ListView.separated(
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

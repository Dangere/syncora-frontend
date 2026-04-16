import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/filter_list.dart';
import 'package:syncora_frontend/common/widgets/profile_picture.dart';
import 'package:syncora_frontend/core/data/enums/groups_filter.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_provider.dart';
import 'package:syncora_frontend/core/tests.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/users/models/user.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/dashboard/view/widgets/dashboard_search_bar.dart';
import 'package:syncora_frontend/features/groups/groups_provider.dart';
import 'package:syncora_frontend/features/groups/view/popups/group_popups.dart';
import 'package:syncora_frontend/features/groups/view/widgets/group_total_progress_card.dart';
import 'package:syncora_frontend/features/groups/view/widgets/groups_list.dart';
import 'package:syncora_frontend/features/users/providers/users_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final Duration _backgroundTransitionDuration =
      const Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // We assume that the user is logged in and there's always a user provided if we are on this page
    int userId = ref.watch(authProvider).value!.userId!;

    // Warming user provider for the first time
    ref.read(userProvider);

    SnackBarAlerts.registerErrorListener(ref, context);

    void onCreateGroup() async {
      final result = await GroupPopups.createGroupPopup(context);

      if (result != null) {
        ref
            .read(groupsListProvider.notifier)
            .createGroup(title: result.title, description: result.description);
      }
    }

    ref.read(loggerProvider).d("Building dashboard page");
    return Scaffold(
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          AppButton(
            width: 80,
            onPressed: () {
              ref
                  .read(debug_fakeBeingOnlineProvider.notifier)
                  .update((state) => !state);
            },
            size: AppButtonSize.mini,
            style: AppButtonStyle.filled,
            intent: AppButtonIntent.warning,
            child: const Icon(Icons.add),
          ),
          AppButton(
            width: 80,
            onPressed: () async {
              (await ref.read(outboxRepositoryProvider).getPendingEntries())
                  .forEach(
                (element) {
                  print(element.toString());
                },
              );
            },
            size: AppButtonSize.mini,
            style: AppButtonStyle.filled,
            intent: AppButtonIntent.warning,
            child: const Icon(Icons.table_bar),
          ),
          // AppButton(
          //   width: 80,
          //   onPressed: () {
          //     setState(() {
          //       TEMPPPPPPPPPPPPP = true;
          //     });
          //     Tests.populate_groups_and_tasks(ref);
          //   },
          //   size: AppButtonSize.mini,
          //   style: AppButtonStyle.filled,
          //   intent: AppButtonIntent.warning,
          //   child: const Icon(Icons.price_change_outlined),
          // )
        ],
      ),
      body: Stack(
        children: [
          // BACKGROUND GRAPHIC COLORS
          Positioned.fill(
            child: Image.asset(
                width: double.infinity,
                // height: 371,
                // fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                fit: BoxFit.fitWidth,
                "assets/images/background_dashboard_effect.png"),
          ),
          //BACKGROUND GRAPHIC
          Positioned.fill(
            child: Image.asset(
                width: double.infinity,
                // height: 371,
                // fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                fit: BoxFit.fitWidth,
                "assets/images/background_dashboard.png"),
          ),

          Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: CustomScrollView(
                clipBehavior: Clip.hardEdge,
                slivers: [
                  SliverPersistentHeader(
                    delegate: MySliverPersistentHeaderDelegate(
                        child: Center(
                            child: Text(
                                "Connection is ${ref.watch(isOnlineProvider) ? "online" : "offline"}")),
                        height: 30),
                    pinned: true,
                  ),
                  // PROFILE AND SETTINGS HEADER
                  SliverToBoxAdapter(
                    child: Padding(
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
                                      child: IconButton(
                                        padding: const EdgeInsets.all(0),
                                        onPressed: () => context.pushNamed(
                                            "profile-view",
                                            pathParameters: {
                                              "id": userId.toString()
                                            }),
                                        icon: ProfilePicture(
                                          userId: userId,
                                          radius: 48 / 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ), // disappears on scroll
                  ),
                  // GROUPS PROGRESS
                  SliverToBoxAdapter(
                    child: Container(
                      // color: Colors.blue,
                      child: Padding(
                          padding: EdgeInsets.only(
                              top: AppSpacing.paddingVerticalXl.top,
                              left: AppSpacing.paddingHorizontalLg.left,
                              right: AppSpacing.paddingHorizontalLg.right),
                          child: const GroupTotalProgressCard()),
                    ), // disappears on scroll
                  ),

                  // SEARCH BAR
                  SliverPersistentHeader(
                      delegate: MySliverPersistentHeaderDelegate(
                          child: const Padding(
                            padding: AppSpacing.paddingVerticalLg,
                            child: DashboardSearchBar(),
                          ),
                          height: 100),
                      pinned: true),

                  // CREATE GROUP BUTTON AND FILTERS
                  SliverPersistentHeader(
                      delegate: MySliverPersistentHeaderDelegate(
                          child: Container(
                            // padding: AppSpacing.paddingVerticalLg,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(40.0),
                                  topRight: Radius.circular(40.0)),
                            ),
                            child: Column(
                              children: [
                                AppSpacing.verticalSpaceLg,
                                // TITLE AND CREATE GROUP
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // TITLE
                                    Padding(
                                      padding: AppSpacing.paddingHorizontalLg,
                                      child: Text(
                                        AppLocalizations.of(context)
                                            .dashboardPage_MyGroups,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall!
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    // CREATE GROUP
                                    AppButton(
                                      width: 152,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.lg),
                                      // variant: AppButtonVariant.wide,
                                      onPressed: onCreateGroup,
                                      size: AppButtonSize.mini,
                                      style: AppButtonStyle.filled,
                                      intent: AppButtonIntent.primary,
                                      fontSize: 16,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Icon(Icons.add),
                                          Text(
                                            AppLocalizations.of(context)
                                                .dashboardPage_CreateGroup,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                AppSpacing.verticalSpaceLg,
                                // FILTERS FOR GROUPS
                                FilterList<GroupsFilter>(
                                  providerListenable: groupsListProvider,
                                  multiSelect: true,
                                  disable: false,
                                  initialValue: ref
                                      .read(groupsListProvider.notifier)
                                      .filters,
                                  items: [
                                    FilterListItem(
                                      title: AppLocalizations.of(context)
                                          .filter_Completed,
                                      value: GroupsFilter.completed,
                                      opposites: [GroupsFilter.inProgress],
                                      countFactory: (arg) => ref
                                          .read(groupsListProvider.notifier)
                                          .getGroupsCount([arg]),
                                    ),
                                    FilterListItem(
                                      title: AppLocalizations.of(context)
                                          .filter_InProgress,
                                      value: GroupsFilter.inProgress,
                                      opposites: [GroupsFilter.completed],
                                      countFactory: (arg) => ref
                                          .read(groupsListProvider.notifier)
                                          .getGroupsCount([arg]),
                                    ),
                                    FilterListItem(
                                      title: AppLocalizations.of(context)
                                          .filter_Owned,
                                      value: GroupsFilter.owned,
                                      opposites: [GroupsFilter.shared],
                                    ),
                                    FilterListItem(
                                      title: AppLocalizations.of(context)
                                          .filter_Shared,
                                      value: GroupsFilter.shared,
                                      opposites: [GroupsFilter.owned],
                                    ),
                                    FilterListItem(
                                      title: AppLocalizations.of(context)
                                          .filter_Newest,
                                      value: GroupsFilter.newest,
                                      opposites: [GroupsFilter.oldest],
                                    ),
                                    FilterListItem(
                                      title: AppLocalizations.of(context)
                                          .filter_Oldest,
                                      value: GroupsFilter.oldest,
                                      opposites: [GroupsFilter.newest],
                                    ),
                                  ],
                                  onTap: (arg) {
                                    ref
                                        .read(groupsListProvider.notifier)
                                        .filterGroups(arg);
                                  },
                                ),
                                // const SizedBox(height: AppSpacing.lg / 2),
                              ],
                            ),
                          ),
                          height: 130),
                      pinned: true),

                  // GROUPS LIST
                  const GroupsList()
                ],
              ))
        ],
      ),
    );
  }
}

class MySliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  MySliverPersistentHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(context, shrinkOffset, overlapsContent) => child;

  @override
  bool shouldRebuild(covariant MySliverPersistentHeaderDelegate old) =>
      old.child != child;
}

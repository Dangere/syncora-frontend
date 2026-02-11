import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/core/image/image_provider.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/tests.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/features/dashboard/view/widgets/dashboard_searchbar.dart';
import 'package:syncora_frontend/features/groups/view/popups/group_popups.dart';
import 'package:syncora_frontend/features/groups/view/widgets/groups_list.dart';
import 'package:syncora_frontend/features/users/viewmodel/users_providers.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool foldProgressCard = false;
  @override
  Widget build(BuildContext context) {
    // We assume that the user is logged in and there's always a user provided if we are on this page
    // User user = ref.read(authNotifierProvider).value!.user!;
    SnackBarAlerts.registerErrorListener(ref, context);

    void createGroupPopup() {
      GroupPopups.createGroupPopup(context, ref);
    }

    void shouldFoldProgressCard(bool fold) {
      // setState(() {
      //   foldProgressCard = fold;
      // });
    }

    ref.read(loggerProvider).d("Building dashboard page");
    return Scaffold(
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          AppButton(
            width: 80,
            onPressed: () {
              Tests.test_profile_picture(ref);
              // ref.read(loggerProvider).w(ref.read(connectionProvider));
            },
            size: AppButtonSize.icon,
            style: AppButtonStyle.filled,
            intent: AppButtonIntent.warning,
            child: const Icon(Icons.picture_as_pdf),
          ),
          AppButton(
            width: 80,
            onPressed: () {
              ref
                  .read(debug_fakeBeingOnlineProvider.notifier)
                  .update((state) => !state);
            },
            size: AppButtonSize.icon,
            style: AppButtonStyle.filled,
            intent: AppButtonIntent.warning,
            child: const Icon(Icons.add),
          )
        ],
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
                Text(ref.watch(connectionProvider).toString()),
                // SETTINGS AND PROFILE BUTTONS
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
                // Padding(
                //   padding: AppSpacing.paddingHorizontalLg,
                //   child: AnimatedSize(
                //     duration: const Duration(milliseconds: 500),
                //     curve: Curves.easeOutCirc,
                //     child: SizedBox(
                //       height: foldProgressCard ? 50 : 182,
                //       child: GestureDetector(
                //         onTap: () => shouldFoldProgressCard(false),
                //         child: Container(
                //           color: Colors.amber,
                //           child: const Center(
                //             child: Icon(Icons.group),
                //           ),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                // const SizedBox(height: AppSpacing.lg),

                // SEARCH BAR
                GestureDetector(
                    onTap: () => shouldFoldProgressCard(true),
                    child: const DashboardSearchBar()),
                const SizedBox(height: AppSpacing.md),

                // GROUPS
                Expanded(
                  child: GestureDetector(
                    onTap: () => shouldFoldProgressCard(true),
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
                            // TITLE AND CREATE GROUP BUTTON
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    width: 150,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg),
                                    // variant: AppButtonVariant.wide,
                                    onPressed: createGroupPopup,
                                    size: AppButtonSize.small,
                                    style: AppButtonStyle.filled,
                                    intent: AppButtonIntent.primary,
                                    fontSize: 16,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(Icons.add),
                                        Text(
                                          AppLocalizations.of(context)
                                              .dashboardPage_CreateGroup,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

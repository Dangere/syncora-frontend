import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_sizes.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/language_button.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/view/widgets/group_panel.dart';

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

    ref.read(loggerProvider).d("Building dashboard page");
    return Scaffold(
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
            padding: EdgeInsets.only(top: AppSpacing.xl),
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
                SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(40.0),
                          topRight: Radius.circular(40.0)),
                    ),
                    child: ListView.separated(
                        itemBuilder: (context, index) {
                          return GroupPanel(
                              group: Group(
                                  id: index,
                                  title:
                                      "Project 00$index - ${index + 1}th Sprint",
                                  creationDate: DateTime.now(),
                                  ownerUserId: 1,
                                  groupMembersIds: List.generate(
                                      Random().nextInt(6), (index) => 1),
                                  tasksIds: List.generate(
                                      Random().nextInt(20), (index) => 1),
                                  description:
                                      "In this sprint we are finishing all de are finishing all design related tasks."
                                          .substring(
                                              0, Random().nextInt(40) + 36)));
                        },
                        separatorBuilder: (context, index) {
                          return const SizedBox(
                            height: 16,
                          );
                        },
                        itemCount: 5),
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

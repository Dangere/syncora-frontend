import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
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
      body: Padding(
        padding: AppSpacing.paddingVerticalXl,
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              flex: 1,
              child: Container(
                color: Theme.of(context).colorScheme.secondary,
                child: Row(
                  children: [
                    const LanguageButton(),
                    IconButton(
                        onPressed: () => context.pushNamed("settings"),
                        icon: const Icon(Icons.settings)),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: ListView.separated(
                  itemBuilder: (context, index) {
                    return GroupPanel(
                        group: Group(
                            id: index,
                            title: "Project 00$index - ${index + 1}th Sprint",
                            creationDate: DateTime.now(),
                            ownerUserId: 1,
                            groupMembersIds: List.generate(
                                Random().nextInt(6), (index) => 1),
                            tasksIds: List.generate(
                                Random().nextInt(20), (index) => 1),
                            description:
                                "In this sprint we are finishing all de are finishing all design related tasks."
                                    .substring(0, Random().nextInt(40) + 36)));
                  },
                  separatorBuilder: (context, index) {
                    return const SizedBox(
                      height: 16,
                    );
                  },
                  itemCount: 5),
            ),
          ],
        ),
      ),
    );
  }
}

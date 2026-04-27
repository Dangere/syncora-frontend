import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/marquee_widget.dart';
import 'package:syncora_frontend/common/widgets/progress_bar.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/features/groups/groups_provider.dart';
import 'package:syncora_frontend/features/groups/models/group_progress.dart';
import 'package:syncora_frontend/features/groups/view/widgets/group_progress_card.dart';

class GroupsProgressPage extends ConsumerStatefulWidget {
  const GroupsProgressPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _GroupsProgressPageState();
}

class _GroupsProgressPageState extends ConsumerState<GroupsProgressPage> {
  GroupProgress? totalProgress;

  Future<List<GroupProgress>> getProgress() async {
    totalProgress = await ref
        .read(groupsListProvider.notifier)
        .getGroupsTotalProgress(true, 30);
    return await ref
        .read(groupsListProvider.notifier)
        .getGroupsProgress(true, 30);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(AppLocalizations.of(context).dashboardPage_Monthly_Progress),
        centerTitle: true,
      ),
      body: FutureBuilder(
          future: getProgress(),
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return Padding(
              padding: EdgeInsets.only(top: AppSpacing.paddingVerticalXl.top),
              child: Column(
                children: [
                  if (totalProgress != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ProgressBar(
                        percentage: totalProgress!.percentage,
                        gradient: false,
                      ),
                    ),
                  const SizedBox(
                    height: 47,
                    // child: Placeholder(),
                  ),
                  if (asyncSnapshot.hasData &&
                      asyncSnapshot.data != null &&
                      asyncSnapshot.data!.isNotEmpty)
                    Expanded(
                      child: ListView.separated(
                        separatorBuilder: (context, index) {
                          return const SizedBox(
                            height: 24,
                          );
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 20) +
                            const EdgeInsets.only(bottom: 24),
                        itemCount: asyncSnapshot.data!.length,
                        itemBuilder: (context, index) {
                          GroupProgress groupProgress =
                              asyncSnapshot.data![index];

                          return GroupProgressCard(
                            style: GroupProgressCardStyle.menu,
                            groupProgress: groupProgress,
                            onExpand: () => context
                                .push("/group/${groupProgress.groupId}")
                                .whenComplete(
                              () {
                                setState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          }),
    );
  }
}

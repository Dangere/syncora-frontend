import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/features/groups/groups_provider.dart';
import 'package:syncora_frontend/features/groups/models/group_progress.dart';
import 'package:syncora_frontend/features/groups/view/widgets/group_progress_card.dart';

class GroupTotalProgressCard extends ConsumerStatefulWidget {
  const GroupTotalProgressCard({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _GroupTotalProgressCardState();
}

class _GroupTotalProgressCardState
    extends ConsumerState<GroupTotalProgressCard> {
  GroupProgress? groupProgress;

  double tempProgress = 0;

  @override
  Widget build(BuildContext context) {
    ref.watch(groupsProvider.select((groupState) {
      return groupState.value;
    }));
    return FutureBuilder(
        future:
            ref.read(groupsProvider.notifier).getGroupsTotalProgress(true, 30),
        builder: (context, asyncSnapshot) {
          if (asyncSnapshot.connectionState == ConnectionState.waiting &&
              groupProgress == null) {
            return const Center(child: CircularProgressIndicator());
          }

          groupProgress = asyncSnapshot.data;

          if (asyncSnapshot.data == null) return Container();
          if (asyncSnapshot.hasData && asyncSnapshot.requireData == null)
            return Container();

          ref.read(loggerProvider).f(groupProgress.toString());

          return GroupProgressCard(
              groupProgress: groupProgress!.copyWith(
                  groupTitle: AppLocalizations.of(context)!.filter_InProgress),
              onExpand: () => context.push('/groups-progress').whenComplete(
                    () => setState(() {}),
                  ));
        });
  }
}

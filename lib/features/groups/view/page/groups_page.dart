import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/viewmodel/group_viewmodel.dart';

class GroupsPage extends ConsumerStatefulWidget {
  const GroupsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _GroupsFrontPageState();
}

class _GroupsFrontPageState extends ConsumerState<GroupsPage> {
  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupNotifierProvider);

    List<Group> groupsList = groups.value ?? [];

    SnackBarAlerts.registerErrorListener(ref, context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(AppLocalizations.of(context).groupsFrontPageTitle),
      ),
      body: OverlayLoader(
          isLoading: groups.isLoading,
          overlay: const Center(child: CircularProgressIndicator()),
          body: ListView.builder(
            itemCount: groupsList.length,
            itemBuilder: (context, index) => Text(groupsList[index].title),
          )),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () =>
            ref.read(groupNotifierProvider.notifier).createGroup('New group'),
      ),
    );
  }
}

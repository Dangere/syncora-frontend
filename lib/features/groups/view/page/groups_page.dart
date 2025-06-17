import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/alert_dialogs.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/core/utils/validators.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';

class GroupsPage extends ConsumerStatefulWidget {
  const GroupsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _GroupsFrontPageState();
}

class _GroupsFrontPageState extends ConsumerState<GroupsPage> {
  String newGroupTitle = '';
  String newGroupDescription = '';

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsNotifierProvider);

    List<Group> groupsList = groups.value ?? [];

    SnackBarAlerts.registerErrorListener(ref, context);

    void createGroup() {
      ref
          .read(groupsNotifierProvider.notifier)
          .createGroup(newGroupTitle, newGroupDescription);
    }

    void groupDescriptionPopup() {
      print("groupDescriptionPopup");
      AlertDialogs.showTextFieldDialog(context,
          barrierDismissible: true,
          blurBackground: false,
          message: "New Group Description",
          onContinue: (p0) {
            newGroupDescription = p0;
            createGroup();
          },
          validation: (p0) => Validators.validateGroupDescription(p0)
              ? null
              : "Invalid description");
    }

    void groupTitlePopup() {
      AlertDialogs.showTextFieldDialog(context,
          barrierDismissible: true,
          blurBackground: false,
          message: "New Group title",
          onContinue: (p0) {
            newGroupTitle = p0;
            print(newGroupTitle);
            groupDescriptionPopup();
          },
          validation: (p0) =>
              Validators.validateGroupTitle(p0) ? null : "Invalid title");
    }

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
          onPressed: groupTitlePopup, child: const Icon(Icons.add)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/common/widgets/syncing_icon.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/syncing/sync_notifier.dart';
import 'package:syncora_frontend/core/utils/alert_dialogs.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/core/utils/validators.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
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
  void initState() {
    Future.microtask(() {
      if (!ref.read(isGuestProvider))
        ref.read(syncBackendProvider.notifier).sync();
    });
    // ref.read(syncBackendProvider.notifier).sync();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsNotifierProvider);

    List<Group> groupsList = groups.hasValue ? groups.value! : List.empty();

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

    if (groups.hasError) {
      return Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(AppLocalizations.of(context).groupsFrontPageTitle),
            actions: [
              if (!ref.read(isGuestProvider)) const SyncingIcon(),
              // IconButton(
              //   icon: const Icon(Icons.shopping_cart),
              //   tooltip: 'Open shopping cart',
              //   onPressed: () {
              //     // handle the press
              //   },
              // ),
            ]),
        body: Center(child: Text(groups.error.toString())),
      );
    }

    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(AppLocalizations.of(context).groupsFrontPageTitle),
          actions: [
            if (!ref.read(isGuestProvider))
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: SyncingIcon(),
              ),
          ]),
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

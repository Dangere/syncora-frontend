import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/core/utils/alert_dialogs.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/core/utils/validators.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/view/widgets/group_panel.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';
import 'package:syncora_frontend/features/users/services/users_service.dart';
import 'package:syncora_frontend/features/users/viewmodel/users_providers.dart';

class GroupsList extends ConsumerStatefulWidget {
  const GroupsList({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _GroupsListState();
}

class _GroupsListState extends ConsumerState<GroupsList> {
  String newGroupTitle = '';
  String newGroupDescription = '';

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsNotifierProvider);
    UsersService usersService = ref.read(usersServiceProvider);

    List<Group> groupsList = groups.hasValue ? groups.value! : List.empty();

    if (groups.hasError) {
      return Center(child: Text(groups.error.toString()));
    }
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

    List<Widget> panels() {
      List<Widget> groupPanels = List.generate(
        groupsList.length,
        (index) => GestureDetector(
          onTap: () => context.push('/group-view/${groupsList[index].id}'),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GroupPanel(
              group: groupsList[index],
            ),
          ),
        ),
      );

      groupPanels.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: 100,
          width: 170,
          child: Center(
              child: ElevatedButton(
                  onPressed: groupTitlePopup, child: Text("Create Group"))),
        ),
      ));

      return groupPanels;
    }

    return OverlayLoader(
      isLoading: groups.isLoading,
      overlay: const Center(child: CircularProgressIndicator()),
      body: SingleChildScrollView(
        child: Wrap(
          alignment: WrapAlignment.center,
          children: panels(),
        ),
      ),
    );
  }
}

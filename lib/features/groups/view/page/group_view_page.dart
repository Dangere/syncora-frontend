import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';
import 'package:syncora_frontend/features/users/services/users_service.dart';
import 'package:syncora_frontend/features/users/viewmodel/users_providers.dart';

class GroupViewPage extends ConsumerStatefulWidget {
  final int groupId;
  const GroupViewPage({super.key, required this.groupId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _GroupViewPageState();
}

class _GroupViewPageState extends ConsumerState<GroupViewPage> {
  // Group group = Group(
  //     id: 0,
  //     title: "HUSDHFIUSDHI",
  //     description: null,
  //     creationDate: DateTime.now(),
  //     ownerUserId: 0,
  //     groupMembers: []);

  @override
  Widget build(BuildContext context) {
    UsersService usersService = ref.read(usersServiceProvider);
    Group group = ref.watch(groupProvider(widget.groupId)).value!;
    return Scaffold(
      appBar: AppBar(title: const Text("Group View")),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(group.title),
            Text(group.description == null || group.description!.isEmpty
                ? "No description"
                : group.description!),
            Text(group.groupMembers.length.toString()),
          ],
        ),
      ),
      // This button will update the groups, but we shouldnt rebuild this widget cuz we are supposedly listening to a change in one specific group
      floatingActionButton: FloatingActionButton(onPressed: () {
        ref.read(groupsNotifierProvider.notifier).reloadGroups();
      }),
    );
  }
}

// a quick and dirty class used to test different parts of the app
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:lorem_ipsum/lorem_ipsum.dart';
import 'package:sqflite/sqflite.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/data/enums/database_tables.dart';
import 'package:syncora_frontend/core/image/image_providers.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_sorter.dart';
import 'package:syncora_frontend/core/network/syncing/model/sync_payload.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/users/models/user.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/models/group_dto.dart';
import 'package:syncora_frontend/features/groups/models/group_progress.dart';
import 'package:syncora_frontend/features/groups/repositories/statistics_repository.dart';
import 'package:syncora_frontend/features/groups/groups_provider.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';
import 'package:syncora_frontend/features/tasks/tasks_provider.dart';
import 'package:syncora_frontend/features/users/providers/users_provider.dart';

class Tests {
  // 2. Turns out it was because of the mapping from the json to the payload, the backend would return the "completed" property as a bool
  // But i was expecting it as an int like how the local db handles bools

  static void test_print_user_progress(WidgetRef ref) async {
    int userId = ref.read(authProvider).value!.userId!;

    List<GroupProgress> progress = await ref
        .read(groupStatisticsProvider)
        .getProgressSince(userId, 30, true);

    progress.forEach((p) => Logger().d(p.toString()));
  }

  static void test_Json_To_SyncPayload(WidgetRef ref) async {
    String jsonString = """
    {
      "timestamp": "2025-09-23T10:15:55.4431826Z",
      "groups": [
        {
          "id": 13,
          "title": "lelle new group lele",
          "description": "New discription",
          "creationDate": "2025-09-23T10:13:30.166782Z",
          "lastModifiedDate": "2025-09-23T10:13:30.166824Z",
          "ownerUserId": 5,
          "groupMembers": []
        }
      ],
      "users": [],
      "tasks": [
        {
          "id": 20,
          "title": "123123",
          "description": null,
          "completed": true,
          "completedById": 5,
          "creationDate": "2025-09-23T10:13:50.222642Z",
          "lastModifiedDate": "2025-09-23T10:14:05.265717Z",
          "groupId": 13
        }
      ]
    }
    """;

    Map<String, dynamic> json = jsonDecode(jsonString);

    SyncPayload payload = SyncPayload.fromJson(json);

    Logger().d(payload.toString(),
        stackTrace: StackTrace.fromString("Mapped payload"));
  }

  // 1. The problem started here were i was not getting the task completed despite it being set to true
  static void test_Inserting_Tasks_LocalDb(WidgetRef ref) async {
    int userId = ref.read(authProvider.select((value) => value.value!.userId!));

    // Creating group
    GroupDTO group = GroupDTO(
      id: 1,
      title: "Group 1",
      description: "Description 1",
      ownerUserId: userId,
      creationDate: DateTime.now(),
      groupMembersIds: [],
    );

    // Creating a completed task that belongs to the group
    Task task = Task(
      id: 1,
      groupId: group.id,
      title: "Task 1",
      description: "Description 1",
      assignedTo: [],
      completedById: userId,
      creationDate: DateTime.now(),
    );

    // Inserting the group
    await ref.read(localGroupsRepositoryProvider).upsertGroups([group]);

    // Inserting the task
    await ref.read(localTasksRepositoryProvider).upsertTasks([task]);

    // Printing the database and expecting a completed task
    await printDb(await ref.read(localDbProvider).getDatabase());

    // Getting the tasks for the group
    Result<List<Task>> tasks =
        await ref.read(tasksServiceProvider).getTasksForGroup(group.id, []);

    print(tasks.data!.first.completedById);
  }

  // static void test_negative_id(WidgetRef ref, BuildContext context) async {
  //   AlertDialogs.showTextFieldDialog(
  //     context,
  //     barrierDismissible: true,
  //     blurBackground: false,
  //     message: "message",
  //     onContinue: (p0) async {
  //       Database db = await ref.read(localDbProvider).getDatabase();
  //       Logger().f(await db.update(
  //         DatabaseTables.groups,
  //         {"id": 44444444444},
  //         where: "id = ?",
  //         whereArgs: [p0],
  //       ));
  //     },
  //     validation: (arg) {},
  //   );
  // }

  static void test_outbox_sorter() {
    List<OutboxEntry> entries = [
      OutboxEntry(
        id: 25789,
        entityType: OutboxEntityType.task,
        actionType: OutboxActionType.delete,
        entityId: -2332,
        status: OutboxStatus.pending,
        creationDate: DateTime.now(),
      ),
      OutboxEntry(
        id: 57893,
        entityType: OutboxEntityType.group,
        actionType: OutboxActionType.update,
        entityId: -2442,
        status: OutboxStatus.pending,
        creationDate: DateTime.now(),
      ),
      OutboxEntry(
        id: 8757894,
        entityType: OutboxEntityType.task,
        actionType: OutboxActionType.update,
        entityId: -22232,
        status: OutboxStatus.pending,
        creationDate: DateTime.now(),
      ),
      OutboxEntry(
        id: 35789,
        entityType: OutboxEntityType.group,
        actionType: OutboxActionType.update,
        entityId: -2442,
        status: OutboxStatus.pending,
        creationDate: DateTime.now(),
      ),
      OutboxEntry(
        id: 478,
        entityType: OutboxEntityType.task,
        actionType: OutboxActionType.update,
        entityId: -22232,
        status: OutboxStatus.pending,
        creationDate: DateTime.now(),
      ),
      OutboxEntry(
        id: 5789,
        entityType: OutboxEntityType.task,
        actionType: OutboxActionType.mark,
        entityId: -22232,
        status: OutboxStatus.pending,
        creationDate: DateTime.now(),
      ),
      OutboxEntry(
        id: 15789,
        entityType: OutboxEntityType.group,
        actionType: OutboxActionType.create,
        entityId: -232,
        status: OutboxStatus.pending,
        creationDate: DateTime.now(),
      ),
      OutboxEntry(
        id: 45,
        entityType: OutboxEntityType.task,
        actionType: OutboxActionType.create,
        entityId: -2222,
        status: OutboxStatus.pending,
        creationDate: DateTime.now(),
      ),
      OutboxEntry(
        id: 4,
        entityType: OutboxEntityType.task,
        actionType: OutboxActionType.mark,
        entityId: -22232,
        status: OutboxStatus.pending,
        creationDate: DateTime.now(),
      ),
      OutboxEntry(
        id: 5784,
        entityType: OutboxEntityType.task,
        actionType: OutboxActionType.create,
        entityId: -2222,
        status: OutboxStatus.pending,
        creationDate: DateTime.now(),
      ),
      OutboxEntry(
        id: 19,
        entityType: OutboxEntityType.group,
        actionType: OutboxActionType.create,
        entityId: -232,
        status: OutboxStatus.pending,
        creationDate: DateTime.now(),
      ),
    ];

    var sortedEntries = OutboxSorter.sort(entries);
    // Priority, Create group -> modify group -> create task -> modify task
    Logger().f(sortedEntries);
  }

  static void test_group_query(WidgetRef ref) async {
    Database db = await ref.read(localDbProvider).getDatabase();

    // String groupQuery = '''SELECT
    //     id, clientGeneratedId, ownerUserId, title, description, creationDate,
    //     (SELECT json_group_array(userId) FROM ${DatabaseTables.groupsMembers} WHERE groupId = g.id)
    //     AS members,
    //     (SELECT json_group_array(id) FROM ${DatabaseTables.tasks} WHERE groupId = g.id AND isDeleted = 0)
    //     as tasks
    //     FROM ${DatabaseTables.groups} g
    //     WHERE isDeleted = 0''';

//     String completedTasksQuery = '''
// SELECT Count(id) FROM ${DatabaseTables.tasks} WHERE groupId = 138 AND isDeleted = 0 AND completedById IS NOT NULL
//     ''';

    String groupFilteredQuery = '''SELECT
        id, clientGeneratedId, ownerUserId, title, description, creationDate,
        (SELECT JSON_GROUP_ARRAY(completedById) FROM ${DatabaseTables.tasks} WHERE groupId = g.id AND isDeleted = 0)
        as tasks,
        (EXISTS (
        SELECT 1
          FROM ${DatabaseTables.tasks}
          WHERE groupId = g.id AND isDeleted = 0)
        AND NOT EXISTS (
          SELECT 1
          FROM ${DatabaseTables.tasks}
          WHERE groupId = g.id AND isDeleted = 0 AND completedById IS NULL
        )) AS completed
        FROM ${DatabaseTables.groups} g
        WHERE isDeleted = 0''';

    var rawQuery = await db.rawQuery(groupFilteredQuery);

    Logger().f(rawQuery);
  }

  // Apparently i was told (ai told me) that i cant use column aliases in where clause, which is odd cuz i did and it was working so ill test it here
  // Surprise surprise, it works fine, turns out sqflite does allow column aliases in where clause as a non-standard extension to the SQL language
  // Dont blindly follow AI
  static void column_alias_in_where_clause(WidgetRef ref) async {
    Database db = await ref.read(localDbProvider).getDatabase();
    String groupsQuery = '''
        SELECT
        id, clientGeneratedId, ownerUserId, title, description, creationDate,
        (EXISTS (
        SELECT 1
          FROM ${DatabaseTables.tasks}
          WHERE groupId = g.id AND isDeleted = 0)
        AND NOT EXISTS (
          SELECT 1
          FROM ${DatabaseTables.tasks}
          WHERE groupId = g.id AND isDeleted = 0 AND completedById IS NULL
        )) AS completed
        FROM ${DatabaseTables.groups} g
        WHERE isDeleted = 0 AND completed = 1''';

    var result = await db.rawQuery(groupsQuery);

    Logger().f(result);
  }

  static void testing_statistics_for_group_count(WidgetRef ref) async {
    // Database db = await ref.read(localDbProvider).getDatabase();
    StatisticsRepository statisticsRepository =
        StatisticsRepository(ref.read(localDbProvider));

    var result =
        await statisticsRepository.getGroupsCount([GroupsFilter.inProgress], 1);

    Logger().f(result);
  }

  static void populate_groups(WidgetRef ref, int count) async {
    // Database db = await ref.read(localDbProvider).getDatabase();

    for (var i = 0; i < count; i++) {
      String title = loremIpsum(paragraphs: 1, words: Random().nextInt(4) + 1);

      String description =
          loremIpsum(paragraphs: 1, words: 10 + Random().nextInt(10));

      await ref
          .read(groupsProvider.notifier)
          .createGroup(title: title, description: description);
    }
  }

  static void populate_groups_and_tasks(WidgetRef ref) async {
// Group 1: The Unhinged Political/Social Calendar
    Result<Group> group1 = await ref
        .read(groupsServiceProvider)
        .createGroup("Weekend Plans", "things to do this weekend");
    int group1Id = group1.data!.id;
    await ref
        .read(tasksServiceProvider)
        .createTask(groupId: group1Id, title: "attend charlie kirk's debate");
    await ref
        .read(tasksServiceProvider)
        .createTask(groupId: group1Id, title: "Donate 7000 to israel");
    await ref.read(tasksServiceProvider).createTask(
        groupId: group1Id, title: "have an eyebrow hair transplant");
    await ref.read(tasksServiceProvider).createTask(
        groupId: group1Id, title: "Return jordan peterson book to abdul");

// Group 2: The Dementia Arc
    Result<Group> group2 =
        await ref.read(groupsServiceProvider).createGroup("Daily Routine", "");
    int group2Id = group2.data!.id;
    await ref
        .read(tasksServiceProvider)
        .createTask(groupId: group2Id, title: "Take meds for dementia");
    await ref
        .read(tasksServiceProvider)
        .createTask(groupId: group2Id, title: "Ttake meds for dementia");
    await ref
        .read(tasksServiceProvider)
        .createTask(groupId: group2Id, title: "Take meds for dementia");
    await ref
        .read(tasksServiceProvider)
        .createTask(groupId: group2Id, title: "call mike (or was it joe?)");
    await ref.read(tasksServiceProvider).createTask(
        groupId: group2Id, title: "remember why i walked into the kitchen");

// Group 3: The Statue/Bug Spiral
    Result<Group> group3 = await ref
        .read(groupsServiceProvider)
        .createGroup("Errands", "misc stuff");
    int group3Id = group3.data!.id;
    await ref
        .read(tasksServiceProvider)
        .createTask(groupId: group3Id, title: "sell that weird statue on ebey");
    await ref
        .read(tasksServiceProvider)
        .createTask(groupId: group3Id, title: "buy a bug spray");
    await ref
        .read(tasksServiceProvider)
        .createTask(groupId: group3Id, title: "throw away the statue");
    await ref.read(tasksServiceProvider).createTask(
        groupId: group3Id,
        title: "Google if its normal to feel bugs under your skin");
    await ref.read(tasksServiceProvider).createTask(
        groupId: group3Id,
        title: "The bugs under my skin require a new sacrifice");
  }

  static void test_profile_picture(WidgetRef ref, BuildContext context) async {
    Result<XFile?> imagePicked =
        await ref.read(imageServiceProvider).pickImage(ImageSource.gallery);

    if (!imagePicked.isSuccess || imagePicked.data == null) {
      return Logger().e(imagePicked.data == null
          ? "No image picked"
          : imagePicked.error!.message);
    }
    Logger().f("Picked image path: ${imagePicked.data!.path}");
    if (!context.mounted) return;
    Uint8List? croppedImageBytes =
        await context.push<Uint8List>('/crop-image', extra: imagePicked.data!);

    if (croppedImageBytes == null) return Logger().e("No image cropped");
    Logger().f("Successfully cropped image");

    Result<String> uploadedImageUrl =
        await ref.read(imageServiceProvider).uploadImage(croppedImageBytes);

    if (!uploadedImageUrl.isSuccess) {
      return Logger().e(uploadedImageUrl.error!.message);
    }

    Logger().f("Successfully uploaded image: ${uploadedImageUrl.data}");

    Result updateImageResult = await ref
        .read(usersServiceProvider)
        .updateProfilePicture(uploadedImageUrl.data!);

    if (context.mounted) {
      if (!updateImageResult.isSuccess) {
        SnackBarAlerts.showErrorSnackBar(
            updateImageResult.error!.message, context);
      } else {
        SnackBarAlerts.showSuccessSnackBar("Changed profile picture!", context);
      }
    }
    if (!updateImageResult.isSuccess) {
      return Logger().e(updateImageResult.error!.message);
    }
  }

  // static void update_user_object_state(WidgetRef ref) async {
  //   User currentUser = ref.read(authProvider).value!.userId!;

  //   // ref.read(authProvider.notifier).updateUser(currentUser.copyWith(
  //   //     pfpURL:
  //   //         "https://wallpapers-clan.com/wp-content/uploads/2023/06/cool-pfp-03.jpg"));
  // }

  static Future<void> printDb(Database db) async {
    var tasksRawQuery =
        await db.rawQuery("SELECT * FROM ${DatabaseTables.tasks}");
    var groupsRawQuery =
        await db.rawQuery("SELECT * FROM ${DatabaseTables.groups}");
    var usersRawQuery =
        await db.rawQuery("SELECT * FROM ${DatabaseTables.users}");
    var groupMembersRawQuery =
        await db.rawQuery("SELECT * FROM ${DatabaseTables.groupsMembers}");

    var outboxRawQuery =
        await db.rawQuery("SELECT * FROM ${DatabaseTables.outbox}");

    var pendingOutboxQuery = await db.rawQuery(
        "SELECT * FROM ${DatabaseTables.outbox} WHERE status = '${OutboxStatus.pending.index}'");
    List<OutboxEntry> pendingOutboxEntires =
        pendingOutboxQuery.map((e) => OutboxEntry.fromTable(e)).toList();

    // Logger().f(groupsRawQuery, stackTrace: StackTrace.fromString("GROUPS"));
    // Logger().f(usersRawQuery, stackTrace: StackTrace.fromString("USERS"));
    // Logger().f(groupMembersRawQuery,
    //     stackTrace: StackTrace.fromString("GROUP MEMBERS"));

    // Logger().f(tasksRawQuery, stackTrace: StackTrace.fromString("TASKS"));
    // Logger().f(outboxRawQuery, stackTrace: StackTrace.fromString("OUTBOX"));

    Logger().f(pendingOutboxEntires.map((e) => e.toString()).toList(),
        stackTrace: StackTrace.fromString("PENDING OUTBOX"));
  }
}

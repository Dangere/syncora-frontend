// a quick and dirty class used to test different parts of the app
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/data/enums/database_tables.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_sorter.dart';
import 'package:syncora_frontend/core/network/syncing/model/sync_payload.dart';
import 'package:syncora_frontend/core/utils/alert_dialogs.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/models/group_dto.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';
import 'package:syncora_frontend/features/tasks/viewmodel/tasks_providers.dart';

class Tests {
  // Testing the inserting and retrieving of data from the local database
  static void test_LocalDb(WidgetRef ref) async {
    printDb(ref);
  }

  // 2. Turns out it was because of the mapping from the json to the payload, the backend would return the "completed" property as a bool
  // But i was expecting it as an int like how the local db handles bools
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
    int userId =
        ref.read(authNotifierProvider.select((value) => value.value!.user!.id));

    // Creating group
    GroupDTO group = GroupDTO(
      id: 1,
      title: "Group 1",
      description: "Description 1",
      ownerUserId: userId,
      creationDate: DateTime.now(),
      groupMembers: [],
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
    await ref.read(groupsServiceProvider).upsertGroups([group]);

    // Inserting the task
    await ref.read(tasksServiceProvider).upsertTasks([task]);

    // Printing the database and expecting a completed task
    await printDb(ref);

    // Getting the tasks for the group
    Result<List<Task>> tasks =
        await ref.read(tasksServiceProvider).getTasksForGroup(group.id);

    print(tasks.data!.first.completedById);
  }

  static void test_negative_id(WidgetRef ref, BuildContext context) async {
    AlertDialogs.showTextFieldDialog(
      context,
      barrierDismissible: true,
      blurBackground: false,
      message: "message",
      onContinue: (p0) async {
        Database db = await ref.read(localDbProvider).getDatabase();
        Logger().f(await db.update(
          DatabaseTables.groups,
          {"id": 44444444444},
          where: "id = ?",
          whereArgs: [p0],
        ));
      },
      validation: (arg) {},
    );
  }

  static void test_outbox_sorter() {
    List<OutboxEntry> entries = [
      OutboxEntry(
        id: 2,
        entityType: OutboxEntityType.task,
        actionType: OutboxActionType.delete,
        entityId: -2332,
        status: OutboxStatus.pending,
        payload: {},
        creationDate: DateTime.now(),
      ),
      OutboxEntry(
        id: 3,
        entityType: OutboxEntityType.group,
        actionType: OutboxActionType.update,
        entityId: -2442,
        status: OutboxStatus.pending,
        payload: {},
        creationDate: DateTime.now(),
      ),
      OutboxEntry(
        id: 4,
        entityType: OutboxEntityType.task,
        actionType: OutboxActionType.update,
        entityId: -22232,
        status: OutboxStatus.pending,
        payload: {},
        creationDate: DateTime.now(),
      ),
      OutboxEntry(
        id: 4,
        entityType: OutboxEntityType.task,
        actionType: OutboxActionType.mark,
        entityId: -22232,
        status: OutboxStatus.pending,
        payload: {},
        creationDate: DateTime.now(),
      ),
      OutboxEntry(
        id: 4,
        entityType: OutboxEntityType.task,
        actionType: OutboxActionType.create,
        entityId: -2222,
        status: OutboxStatus.pending,
        payload: {},
        creationDate: DateTime.now(),
      ),
      OutboxEntry(
        id: 1,
        entityType: OutboxEntityType.group,
        actionType: OutboxActionType.create,
        entityId: -232,
        status: OutboxStatus.pending,
        payload: {},
        creationDate: DateTime.now(),
      ),
    ];

    var sortedEntries = OutboxSorter.sort(entries);
    // Priority, Create group -> modify group -> create task -> modify task
    Logger().f(sortedEntries);
  }

  static Future<void> printDb(WidgetRef ref) async {
    Database db = await ref.read(localDbProvider).getDatabase();

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

    Logger().f(groupsRawQuery, stackTrace: StackTrace.fromString("GROUPS"));
    Logger().f(usersRawQuery, stackTrace: StackTrace.fromString("USERS"));
    Logger().f(groupMembersRawQuery,
        stackTrace: StackTrace.fromString("GROUP MEMBERS"));

    Logger().f(tasksRawQuery, stackTrace: StackTrace.fromString("TASKS"));
    Logger().f(outboxRawQuery, stackTrace: StackTrace.fromString("OUTBOX"));
  }
}

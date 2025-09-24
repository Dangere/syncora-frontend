import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/core/data/enums/database_tables.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';

class LocalTasksRepository {
  final DatabaseManager _databaseManager;

  LocalTasksRepository(this._databaseManager);

  Future<List<Task>> getTasksForGroup(int groupId) async {
    final db = await _databaseManager.getDatabase();

    List<Map<String, dynamic>> tasks = await db.rawQuery(
        ''' SELECT t.id, t.groupId, t.title, t.description, t.completed, t.completedById, t.creationDate FROM ${DatabaseTables.tasks} AS t
        LEFT JOIN ${DatabaseTables.groups} AS g ON t.groupId = g.id WHERE t.groupId = $groupId''');

    List<Task> taskList = List.empty(growable: true);
    for (var task in tasks) {
      taskList.add(Task.fromJson(task));
    }
    return taskList;
  }

  Future<void> upsertTasks(List<Task> tasks) async {
    // throw UnimplementedError("No upsert method");

    final db = await _databaseManager.getDatabase();

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (Task task in tasks) {
        batch.insert(
          DatabaseTables.tasks,
          task.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // for (var i = 0; i < group.groupMembers.length; i++) {
        //   batch.insert(
        //     DatabaseTables.groupsMembers,
        //     {
        //       "groupId": group.id,
        //       "userId": group.groupMembers[i],
        //     },
        //     conflictAlgorithm: ConflictAlgorithm.replace,
        //   );
        // }
      }
      batch.commit(noResult: true);
    });
  }
}

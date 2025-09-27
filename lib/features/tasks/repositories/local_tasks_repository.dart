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
    List<Map<String, dynamic>> tasks = await db.rawQuery('''
    SELECT 
      t.id, 
      t.groupId, 
      t.title, 
      t.description, 
      t.completedById, 
      t.creationDate,
      GROUP_CONCAT(ts.userId) AS assignedTo
    FROM ${DatabaseTables.tasks} AS t
    LEFT JOIN ${DatabaseTables.tasksAssignees} AS ts ON ts.taskId = t.id
    WHERE t.groupId = ?
    GROUP BY t.id
    ''', [groupId]);

    List<Task> taskList = tasks.map((task) {
      Map<String, dynamic> mutatedTask = Map.from(task);
      final assignedToRaw = mutatedTask["assignedTo"] as String?;
      mutatedTask["assignedTo"] = assignedToRaw != null
          ? assignedToRaw.split(",").map(int.parse).toList()
          : <int>[];
      return Task.fromJson(mutatedTask);
    }).toList();

    for (var i = 0; i < tasks.length; i++) {}
    return taskList;
  }

  Future<void> upsertTasks(List<Task> tasks) async {
    // throw UnimplementedError("No upsert method");

    final db = await _databaseManager.getDatabase();

    List<int> existingTasksIds =
        (await db.rawQuery("SELECT id FROM ${DatabaseTables.tasks}"))
            .map((e) => e["id"] as int)
            .toList();

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (Task task in tasks) {
        if (!existingTasksIds.contains(task.id)) {
          batch.insert(
            DatabaseTables.tasks,
            task.toTable(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        } else {
          batch.update(DatabaseTables.tasks, task.toTable(),
              where: "id = ?", whereArgs: [task.id]);
        }

        batch.delete(DatabaseTables.tasksAssignees,
            where: "taskId = ?", whereArgs: [task.id]);
        for (var i = 0; i < task.assignedTo.length; i++) {
          batch.insert(
            DatabaseTables.tasksAssignees,
            {
              "taskId": task.id,
              "userId": task.assignedTo[i],
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      batch.commit(noResult: true);
    });
  }
}

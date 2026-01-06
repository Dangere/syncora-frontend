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
    WHERE t.groupId = ? AND t.isDeleted = 0
    GROUP BY t.id ORDER BY t.creationDate DESC
    ''', [groupId]);

    List<Task> taskList = tasks.map((task) {
      Map<String, dynamic> mutatedTask = Map.from(task);
      final assignedToRaw = mutatedTask["assignedTo"] as String?;
      mutatedTask["assignedTo"] = assignedToRaw != null
          ? assignedToRaw.split(",").map(int.parse).toList()
          : <int>[];
      return Task.fromJson(mutatedTask);
    }).toList();

    return taskList;
  }

  Future<Task> getTask(int taskId) async {
    final db = await _databaseManager.getDatabase();
    Map<String, dynamic> task = (await db.rawQuery('''
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
    WHERE t.id = ? AND t.isDeleted = 0
    ''', [taskId])).first;

    Map<String, dynamic> mutatedTask = Map.from(task);
    final assignedToRaw = mutatedTask["assignedTo"] as String?;
    mutatedTask["assignedTo"] = assignedToRaw != null
        ? assignedToRaw.split(",").map(int.parse).toList()
        : <int>[];

    Task taskObject = Task.fromJson(mutatedTask);

    return taskObject;
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

  // Method used to update temp ids of tasks to ones issued by the backend
  Future<int> updateTaskId(int tempId, int newId) async {
    final db = await _databaseManager.getDatabase();

    Logger().w(tempId);

    return await db.update(
      DatabaseTables.tasks,
      {"id": newId, "clientGeneratedId": tempId},
      where: "id = ?",
      whereArgs: [tempId],
    );
  }

  Future<int> updateTaskDetails(
      {String? title, String? description, required int taskId}) async {
    final db = await _databaseManager.getDatabase();

    if (title == null && description == null) return 0;

    Map<String, Object?> values = {};
    if (title != null) {
      values["title"] = title;
    }

    if (description != null) {
      values["description"] = description;
    }

    return await db.update(
      DatabaseTables.tasks,
      values,
      where: "id = ?",
      whereArgs: [taskId],
    );
  }

  Future<void> markTaskCompletion(
      {required int taskId, required int userId, required bool isDone}) async {
    final db = await _databaseManager.getDatabase();

    await db.update(
        DatabaseTables.tasks, {"completedById": isDone ? userId : null},
        where: "id = ?", whereArgs: [taskId]);
  }

  // Method used to mark Task as deleted
  Future<int> markTaskAsDeleted(int taskId) async {
    final db = await _databaseManager.getDatabase();

    return await db.update(DatabaseTables.tasks, {"isDeleted": 1},
        where: "id = ?", whereArgs: [taskId]);
  }

  // Method used to unmark Task as deleted
  Future<int> unmarkTaskAsDeleted(int taskId) async {
    final db = await _databaseManager.getDatabase();

    return await db.update(DatabaseTables.tasks, {"isDeleted": 0},
        where: "id = ?", whereArgs: [taskId]);
  }

  // Method used to wipe Tasks marked as deleted
  Future<int> wipeDeletedTask(int taskId) async {
    final db = await _databaseManager.getDatabase();

    return await db.delete(DatabaseTables.tasks,
        where: "isDeleted = ? AND id = ?", whereArgs: [1, taskId]);
  }
}

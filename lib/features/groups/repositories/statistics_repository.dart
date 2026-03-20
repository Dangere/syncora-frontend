import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/core/data/enums/database_tables.dart';
import 'package:syncora_frontend/features/groups/groups_provider.dart';
import 'package:syncora_frontend/features/groups/models/group_progress.dart';

class StatisticsRepository {
  final DatabaseManager _databaseManager;

  StatisticsRepository(this._databaseManager);

  Future<int> getGroupsCount(List<GroupsFilter> filters, int userId) async {
    final db = await _databaseManager.getDatabase();

    final String ownershipFilter = (filters.contains(GroupsFilter.owned) ||
            filters.contains(GroupsFilter.shared))
        ? (filters.contains(GroupsFilter.owned)
            ? "AND ownerUserId = $userId"
            : "AND ownerUserId != $userId")
        : "";

    final String completedFilter = (filters.contains(GroupsFilter.completed) ||
            filters.contains(GroupsFilter.inProgress))
        ? (filters.contains(GroupsFilter.completed)
            ? "AND completed = 1"
            : "AND completed = 0")
        : "";

    final String completedSubQuery = completedFilter.isNotEmpty
        ? '''
        ,(EXISTS (
        SELECT 1
          FROM ${DatabaseTables.tasks}
          WHERE groupId = g.id AND isDeleted = 0)
        AND NOT EXISTS (
          SELECT 1
          FROM ${DatabaseTables.tasks}
          WHERE groupId = g.id AND isDeleted = 0 AND completedById IS NULL
        )) AS completed
        '''
        : "";
    //
    final query = '''
    SELECT COUNT(*) as count
    $completedSubQuery
    FROM ${DatabaseTables.groups} g
    WHERE g.isDeleted = 0
    $ownershipFilter
    $completedFilter
    ''';

    final result = await db.rawQuery(query);
    return result.first['count'] as int;
  }

  Future<GroupProgress?> getTotalProgressSince(
      int userId, int sinceDays, bool includeAssignedTasks) async {
    final db = await _databaseManager.getDatabase();

    final String includeAssignedTasksSubQuery = includeAssignedTasks
        ? '''OR EXISTS (
            SELECT 1 FROM ${DatabaseTables.tasksAssignees} ta WHERE ta.taskId = t.id AND ta.userId = $userId
          )'''
        : "";

    // Query to get group ids and two columns for completed tasks and total tasks in the last `sinceDays` days
    // The EXISTS clause is an index look up to improve performance
    final query = '''
        SELECT 0 AS groupId, TotalProgress AS groupTitle
        COUNT(DISTINCT CASE WHEN t.completedById = $userId THEN t.id END) AS completedTasks,
        COUNT(DISTINCT CASE
          WHEN t.completedById IS NULL
          AND (g.ownerUserId = $userId $includeAssignedTasksSubQuery)
          THEN t.id
        END) AS incompleteTasks
      FROM ${DatabaseTables.groups} g
      LEFT JOIN ${DatabaseTables.tasks} t ON t.groupId = g.id AND t.isDeleted = 0 AND t.creationDate >= datetime('now', '-$sinceDays days')
      WHERE g.isDeleted = 0
    ''';

    final result = await db.rawQuery(query);
    if (result.isEmpty) {
      return null;
    }

    return GroupProgress.fromJson(result.first);
  }

  // Returns a group ids and their completion status in terms of tasks
  Future<List<GroupProgress>> getProgressSince(
      int userId, int sinceDays, bool includeAssignedTasks) async {
    final db = await _databaseManager.getDatabase();

    final String includeAssignedTasksSubQuery = includeAssignedTasks
        ? '''OR EXISTS (
            SELECT 1 FROM ${DatabaseTables.tasksAssignees} ta WHERE ta.taskId = t.id AND ta.userId = $userId
          )'''
        : "";

    // Query to get group ids and two columns for completed tasks and total tasks in the last `sinceDays` days
    // The EXISTS clause is an index look up to improve performance
    final query = '''
        SELECT
        g.id AS groupId, g.title AS groupTitle,
        COUNT(DISTINCT CASE WHEN t.completedById = $userId THEN t.id END) AS completedTasks,
        COUNT(DISTINCT CASE
          WHEN t.completedById IS NULL
          AND (g.ownerUserId = $userId $includeAssignedTasksSubQuery)
          THEN t.id
        END) AS incompleteTasks
      FROM ${DatabaseTables.groups} g
      LEFT JOIN ${DatabaseTables.tasks} t ON t.groupId = g.id AND t.isDeleted = 0  AND t.creationDate >= datetime('now', '-$sinceDays days')
      WHERE g.isDeleted = 0
      GROUP BY g.id
      HAVING completedTasks > 0 OR incompleteTasks > 0
      ORDER BY g.creationDate DESC
          ''';

    final result = await db.rawQuery(query);
    return result.map((e) => GroupProgress.fromJson(e)).toList();
  }
}

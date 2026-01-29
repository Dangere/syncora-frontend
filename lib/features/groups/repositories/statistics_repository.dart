import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/core/data/enums/database_tables.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';

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
}

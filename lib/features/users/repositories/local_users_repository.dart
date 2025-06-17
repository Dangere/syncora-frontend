import 'package:sqflite/sqflite.dart';
import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';

class LocalUsersRepository {
  final DatabaseManager _databaseManager;

  LocalUsersRepository(this._databaseManager);

  Future<void> upsertUser(User user) async {
    final db = await _databaseManager.getDatabase();

    await db.transaction((txn) async {
      await txn.insert(
        "users",
        user.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> upsertAllUsers(List<User> users) async {
    final db = await _databaseManager.getDatabase();

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (User user in users) {
        batch.insert(
          "users",
          user.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      batch.commit(noResult: true);
    });
  }
}

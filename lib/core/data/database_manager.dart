import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:syncora_frontend/core/data/enums/database_target.dart';

class DatabaseManager {
  DatabaseTarget target;

  DatabaseManager({required this.target});

  Future<Database> getDatabase() async {
    String dbFileName;

    switch (target) {
      case DatabaseTarget.user:
        dbFileName = 'syncora_database.db';
        break;
      case DatabaseTarget.guest:
        dbFileName = 'syncora_guest_database.db';
        break;
      default:
        dbFileName = 'syncora_database.db';
    }

    final path = join(await getDatabasesPath(), dbFileName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        pfpURL TEXT
      )
    ''');

    // You need to handle local group creation with ID that is taken by another group on the server when online syncing
    // Introduce a mapping layer
    await db.execute('''
      CREATE TABLE groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ownerId INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        creationDate TEXT NOT NULL,
        FOREIGN KEY(ownerId) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
      
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        completedBy INTEGER,
        completionDate TEXT,
        creationDate TEXT NOT NULL,
        groupId INTEGER NOT NULL,
        FOREIGN KEY(groupId) REFERENCES groups(id) ON DELETE CASCADE ON UPDATE CASCADE
        FOREIGN KEY(completedBy) REFERENCES users(id) ON DELETE NO ACTION ON UPDATE CASCADE

      )
    ''');

    await db.execute('''
      CREATE TABLE groupsMembers (
        id INTEGER PRIMARY KEY,
        groupId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        FOREIGN KEY(groupId) REFERENCES groups(id) ON DELETE CASCADE ON UPDATE CASCADE,
        FOREIGN KEY(userId) REFERENCES users(id) ON UPDATE CASCADE
      )
    ''');
  }

  // Future<void> insertRow(DatabaseTables table, Map<String, Object?> row) async {
  //   // Get a reference to the database.
  //   final db = await getDatabase();

  //   // Insert the Dog into the correct table. You might also specify the
  //   // `conflictAlgorithm` to use in case the same dog is inserted twice.
  //   //
  //   // In this case, replace any previous data.
  //   await db.insert(
  //     table.name,
  //     row,
  //     conflictAlgorithm: ConflictAlgorithm.replace,
  //   );
  // }
}

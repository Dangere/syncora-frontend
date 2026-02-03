import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:syncora_frontend/core/data/enums/database_tables.dart';

class DatabaseManager {
  Database? _db;
  bool mutex = false;
  DatabaseManager();

  Future<Database> getDatabase() async {
    if (_db != null && _db!.isOpen) return _db!;

    while (mutex) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_db != null && _db!.isOpen) return _db!;
    }

    mutex = true;
    String dbFileName = "syncora_database.db";

    Logger().d("Creating database and caching it");

    // If we are on the web we need to use a different factory
    if (kIsWeb) {
      // Change default factory on the web
      databaseFactory = databaseFactoryFfiWeb;

      _db = await databaseFactory.openDatabase(dbFileName,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: _onCreate,
            onConfigure: (db) async {
              await db.execute('PRAGMA foreign_keys = ON');
            },
          ));

      return _db!;
    }

    final path = join(await getDatabasesPath(), dbFileName);
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
    mutex = false;
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DatabaseTables.users}  (
        id INTEGER PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        profilePictureURL TEXT,
        isMainUser INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // You need to handle local group creation with ID that is taken by another group on the server when online syncing
    // Introduce a mapping layer
    await db.execute('''
      CREATE TABLE ${DatabaseTables.groups}  (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientGeneratedId INTEGER,
        ownerUserId INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        creationDate TEXT NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(ownerUserId) REFERENCES ${DatabaseTables.users}(id) ON DELETE CASCADE ON UPDATE CASCADE
      
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseTables.groupsMembers} (
        id INTEGER PRIMARY KEY,
        groupId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        FOREIGN KEY(groupId) REFERENCES  ${DatabaseTables.groups}(id) ON DELETE CASCADE ON UPDATE CASCADE,
        FOREIGN KEY(userId) REFERENCES  ${DatabaseTables.users}(id) ON DELETE CASCADE ON UPDATE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseTables.tasks} (
        id INTEGER PRIMARY KEY,
        clientGeneratedId INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        completedById INTEGER,
        creationDate TEXT NOT NULL,
        groupId INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(groupId) REFERENCES  ${DatabaseTables.groups}(id) ON DELETE CASCADE ON UPDATE CASCADE
        FOREIGN KEY(completedById) REFERENCES  ${DatabaseTables.users}(id) ON DELETE NO ACTION ON UPDATE CASCADE

      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseTables.tasksAssignees} (
        id INTEGER PRIMARY KEY,
        taskId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        FOREIGN KEY(taskId) REFERENCES  ${DatabaseTables.tasks}(id) ON DELETE CASCADE ON UPDATE CASCADE,
        FOREIGN KEY(userId) REFERENCES  ${DatabaseTables.users}(id) ON DELETE CASCADE ON UPDATE CASCADE 
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseTables.syncTimestamps} (
        id INTEGER PRIMARY KEY,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseTables.outbox} (
        id INTEGER PRIMARY KEY,
        entityId INTEGER NOT NULL,
        dependencyId INTEGER,
        entityType INTEGER NOT NULL,
        actionType INTEGER NOT NULL,
        payload TEXT, 
        status INTEGER NOT NULL,
        creationDate TEXT NOT NULL
      )
    ''');
  }

  Future<void> ensureDeleted() async {
    Logger().d("Deleting database");
    String path = await getDatabasesPath();
    await deleteDatabase(join(path, "syncora_database.db"));
    await _db?.close();
    _db = null;
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

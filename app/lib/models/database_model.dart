import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseModel {
  static Database? _db;

  DatabaseModel._constructor();
  static final DatabaseModel instance = DatabaseModel._constructor();

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    _db = await getDatabase();
    return _db!;
  }

  Future<Database> getDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, 'master_db.db');
    final database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: _createDb,
    );
    return database;
  }

  Future _createDb(Database db, int version) async {
    // this method runs only once. when the database is being created

    db.execute("""
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        value REAL,
        date_start INTEGER,
        date_end INTEGER,
        type TEXT,
        is_credit BOOLEAN
      )
    """);
  }

  Future<void> close() async {
    final db = await instance.database;
    return db.close();
  }
}

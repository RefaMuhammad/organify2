import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('organify.db'); // ⬅️ Ubah ke organify.db agar konsisten
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    print('Database path: $path'); // Debug log

    return await openDatabase(
      path,
      version: 3, // ⬅️ Naikan versi untuk memastikan upgrade dijalankan
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        print('Database opened successfully');
        // Verifikasi tabel ada
        var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        print('Tables in database: $tables');
      },
    );
  }

  Future _createDB(Database db, int version) async {
    print('Creating database with version: $version');

    await db.execute('''
      CREATE TABLE login_status (
        id_user INTEGER PRIMARY KEY,
        is_logged_in INTEGER NOT NULL DEFAULT 0,
        is_first_launch INTEGER NOT NULL DEFAULT 1,
        auth_token TEXT
      )
    ''');

    print('Table login_status created successfully');

    // Insert default record
    await db.insert('login_status', {
      'id_user': 1,
      'is_logged_in': 0,
      'is_first_launch': 1,
      'auth_token': null,
    });

    print('Default record inserted');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Check if column exists first
      var result = await db.rawQuery("PRAGMA table_info(login_status)");
      bool hasAuthToken = result.any((column) => column['name'] == 'auth_token');

      if (!hasAuthToken) {
        await db.execute('ALTER TABLE login_status ADD COLUMN auth_token TEXT');
        print('Added auth_token column');
      }
    }

    // Versi 3: Pastikan ada record default
    if (oldVersion < 3) {
      var existing = await db.query('login_status', where: 'id_user = ?', whereArgs: [1]);
      if (existing.isEmpty) {
        await db.insert('login_status', {
          'id_user': 1,
          'is_logged_in': 0,
          'is_first_launch': 1,
          'auth_token': null,
        });
        print('Inserted default record during upgrade');
      }
    }
  }

  /// Simpan/Update status login beserta token JWT
  Future<void> upsertLoginStatus(
      int idUser,
      bool isLoggedIn,
      bool isFirstLaunch, {
        String? authToken,
      }) async {
    try {
      final db = await instance.database;

      await db.insert(
        'login_status',
        {
          'id_user': idUser,
          'is_logged_in': isLoggedIn ? 1 : 0,
          'is_first_launch': isFirstLaunch ? 1 : 0,
          'auth_token': authToken,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('Login status updated for user $idUser');
    } catch (e) {
      print('Error in upsertLoginStatus: $e');
      rethrow;
    }
  }

  /// Update status login saja (tanpa menyentuh token)
  Future<void> updateLoginStatus(int id, bool isLoggedIn) async {
    try {
      final db = await database;
      await db.update(
        'login_status',
        {'is_logged_in': isLoggedIn ? 1 : 0},
        where: 'id_user = ?',
        whereArgs: [id],
      );
      print('Login status updated for user $id: $isLoggedIn');
    } catch (e) {
      print('Error in updateLoginStatus: $e');
      rethrow;
    }
  }

  /// Ambil seluruh status login untuk user tertentu
  Future<Map<String, dynamic>?> getLoginStatus(int idUser) async {
    try {
      final db = await instance.database;

      final result = await db.query(
        'login_status',
        where: 'id_user = ?',
        whereArgs: [idUser],
      );

      if (result.isNotEmpty) {
        print('Login status found for user $idUser: ${result.first}');
        return result.first;
      } else {
        print('No login status found for user $idUser');
        return null;
      }
    } catch (e) {
      print('Error in getLoginStatus: $e');
      return null;
    }
  }

  /// Ambil token login dari SQLite
  Future<String?> getToken(int idUser) async {
    try {
      final db = await instance.database;

      final result = await db.query(
        'login_status',
        columns: ['auth_token'],
        where: 'id_user = ?',
        whereArgs: [idUser],
      );

      if (result.isNotEmpty) {
        String? token = result.first['auth_token'] as String?;
        print('Token found for user $idUser: ${token != null ? 'Yes' : 'No'}');
        return token;
      } else {
        print('No token found for user $idUser');
        return null;
      }
    } catch (e) {
      print('Error in getToken: $e');
      return null;
    }
  }

  Future<void> logoutUser(int idUser) async {
    try {
      final db = await instance.database;

      await db.update(
        'login_status',
        {
          'is_logged_in': 0,
          'auth_token': null,
        },
        where: 'id_user = ?',
        whereArgs: [idUser],
      );

      print('User $idUser logged out successfully');
    } catch (e) {
      print('Error in logoutUser: $e');
      rethrow;
    }
  }

  /// Method untuk debugging - hapus setelah testing
  Future<void> debugDatabase() async {
    try {
      final db = await instance.database;

      // List semua tabel
      var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      print('All tables: $tables');

      // Cek struktur tabel login_status
      var structure = await db.rawQuery("PRAGMA table_info(login_status)");
      print('login_status structure: $structure');

      // Cek isi tabel
      var data = await db.query('login_status');
      print('login_status data: $data');

    } catch (e) {
      print('Error in debugDatabase: $e');
    }
  }

  /// Method untuk reset database - hapus setelah testing
  Future<void> resetDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'organify.db');

      await deleteDatabase(path);
      print('Database deleted');

      _database = null; // Reset instance
      await database; // Recreate database

      print('Database recreated');
    } catch (e) {
      print('Error in resetDatabase: $e');
    }
  }
}
import 'package:hostel_mess_2/core/data/datasources/local/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLiteLocalDatabaseHelper implements LocalDatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    try {
      String path = join(await getDatabasesPath(), 'hostel_mess.db');
      return await openDatabase(
        path,
        version: 3,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute('''
          CREATE TABLE room (
            id INTEGER PRIMARY KEY AUTOINCREMENT, 
            name TEXT NOT NULL UNIQUE
          )
        ''');

          await db.execute('''
          CREATE TABLE student (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL, 
            reg TEXT UNIQUE NOT NULL,
            room_id INTEGER,
            FOREIGN KEY (room_id) REFERENCES room (id) ON DELETE SET NULL
          )
        ''');

          await db.execute('''
          CREATE TABLE food (
            id INTEGER PRIMARY KEY AUTOINCREMENT, 
            name TEXT NOT NULL UNIQUE
          )
        ''');

          await db.execute('''
          CREATE TABLE student_food (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER NOT NULL,
            food_id INTEGER NOT NULL,
            date INTEGER NOT NULL,
            FOREIGN KEY (student_id) REFERENCES student (id) ON DELETE CASCADE,
            FOREIGN KEY (food_id) REFERENCES food (id) ON DELETE CASCADE
          )
        ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            // 1. Create a new table with UNIQUE constraint
            await db.execute('''
            CREATE TABLE room_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE
            )
          ''');

            // 2. Insert unique rooms, keeping the lowest id per name
            await db.execute('''
            INSERT INTO room_new (id, name)
            SELECT MIN(id), name
            FROM room
            GROUP BY name
          ''');

            // 3. Re-map students from duplicate rooms to surviving ids
            await db.execute('''
            UPDATE student
            SET room_id = (
              SELECT MIN(r2.id)
              FROM room r2
              WHERE r2.name = (
                SELECT name FROM room WHERE id = student.room_id
              )
            )
            WHERE room_id IS NOT NULL
          ''');

            // 4. Drop old room table
            await db.execute('DROP TABLE room');

            // 5. Rename new table to room
            await db.execute('ALTER TABLE room_new RENAME TO room');
          }
          if (oldVersion < 3) {
            // 1. Create a new table with UNIQUE constraint
            await db.execute('''
            CREATE TABLE food_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE
            )
          ''');

            // 2. Insert unique foods, keeping the lowest id per name
            await db.execute('''
            INSERT INTO food_new (id, name)
            SELECT MIN(id), name
            FROM food
            GROUP BY name
          ''');

            // 3. Re-map student_food from duplicate foods to surviving ids
            await db.execute('''
            UPDATE student_food
            SET food_id = (
              SELECT MIN(f2.id)
              FROM food f2
              WHERE f2.name = (
                SELECT name FROM food WHERE id = student_food.food_id
              )
            )
            WHERE food_id IS NOT NULL
          ''');

            // 4. Drop old food table
            await db.execute('DROP TABLE food');

            // 5. Rename new table to food
            await db.execute('ALTER TABLE food_new RENAME TO food');
          }
        },
      );
    } catch (e) {
      rethrow; // Let the caller handle DB init errors
    }
  }

  // ---------- Safe CRUD Methods ----------

  @override
  Future<int> addRoom(String name) async {
    try {
      final db = await database;
      return await db.insert('room', {'name': name});
    } catch (e) {
      throw Exception("addRoom failed: $e");
    }
  }

  @override
  Future<int> addStudent(String name, String reg, int? roomId) async {
    try {
      final db = await database;
      return await db.insert('student', {
        'name': name,
        'reg': reg,
        'room_id': roomId,
      });
    } catch (e) {
      throw Exception("addStudent failed: $e");
    }
  }

  @override
  Future<int> addFood(String name) async {
    try {
      final db = await database;
      return await db.insert('food', {'name': name});
    } catch (e) {
      throw Exception("addFood failed: $e");
    }
  }

  @override
  Future<int> addStudentFoodRecord(
    int studentId,
    int foodId,
    DateTime date,
  ) async {
    try {
      final db = await database;
      return await db.insert('student_food', {
        'student_id': studentId,
        'food_id': foodId,
        'date': date.millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception("addStudentFoodRecord failed: $e");
    }
  }

  @override
  Future<int> deleteRoom(int id) async {
    try {
      final db = await database;
      return await db.delete('room', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw Exception("deleteRoom failed: $e");
    }
  }

  @override
  Future<int> deleteStudent(int id) async {
    try {
      final db = await database;
      return await db.delete('student', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw Exception("deleteStudent failed: $e");
    }
  }

  @override
  Future<int> deleteFood(int id) async {
    try {
      final db = await database;
      return await db.delete('food', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw Exception("deleteFood failed: $e");
    }
  }

  @override
  Future<int> deleteStudentFoodRecord(int recordId) async {
    try {
      final db = await database;
      return await db.delete(
        'student_food',
        where: 'id = ?',
        whereArgs: [recordId],
      );
    } catch (e) {
      throw Exception("deleteStudentFoodRecord failed: $e");
    }
  }

  // ---------- Query Methods ----------

  @override
  Future<List<int>> getFoodIdsEatenByStudent(
    int studentId,
    DateTime date,
  ) async {
    try {
      final db = await database;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
        999,
      );
      final result = await db.rawQuery(
        '''
        SELECT food_id FROM student_food
        WHERE student_id = ? AND date >= ? AND date <= ?
      ''',
        [
          studentId,
          startOfDay.millisecondsSinceEpoch,
          endOfDay.millisecondsSinceEpoch,
        ],
      );

      return result.map((row) => row['food_id'] as int).toList();
    } catch (e) {
      throw Exception("getFoodIdsEatenByStudent failed: $e");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentsWhoAteOnDate(
    DateTime date,
  ) async {
    try {
      final db = await database;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
        999,
      );
      return await db.rawQuery(
        '''
        SELECT DISTINCT student.id, student.name
        FROM student_food
        JOIN student ON student.id = student_food.student_id
        WHERE student_food.date >= ? AND student_food.date <= ?
      ''',
        [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
      );
    } catch (e) {
      throw Exception("getStudentsWhoAteOnDate failed: $e");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentMealsOnDate(
    DateTime date,
  ) async {
    try {
      final db = await database;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
        999,
      );
      return await db.rawQuery(
        '''
        SELECT id, student_id, food_id, date
        FROM student_food
        WHERE date >= ? AND date <= ?
      ''',
        [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
      );
    } catch (e) {
      throw Exception("getStudentMealsOnDate failed: $e");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentsForFoodOnDate(
    int foodId,
    DateTime date,
  ) async {
    try {
      final db = await database;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
        999,
      );
      return await db.rawQuery(
        '''
        SELECT s.*
        FROM student s
        INNER JOIN student_food sf ON s.id = sf.student_id
        WHERE sf.food_id = ? AND sf.date >= ? AND sf.date <= ?
      ''',
        [
          foodId,
          startOfDay.millisecondsSinceEpoch,
          endOfDay.millisecondsSinceEpoch,
        ],
      );
    } catch (e) {
      throw Exception("getStudentsForFoodOnDate failed: $e");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllStudentsInRoom(int roomId) async {
    try {
      final db = await database;
      return await db.query(
        'student',
        where: 'room_id = ?',
        whereArgs: [roomId],
      );
    } catch (e) {
      throw Exception("getAllStudentsInRoom failed: $e");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    try {
      final db = await database;
      return await db.query('student');
    } catch (e) {
      throw Exception("getAllStudents failed: $e");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllFood() async {
    try {
      final db = await database;
      return await db.query('food');
    } catch (e) {
      throw Exception("getAllFood failed: $e");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllRooms() async {
    try {
      final db = await database;
      return await db.query('room');
    } catch (e) {
      throw Exception("getAllRooms failed: $e");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentMealHistory(
    int studentId,
  ) async {
    try {
      final db = await database;
      return await db.rawQuery(
        '''
        SELECT food.id AS food_id, food.name AS food_name, student_food.date
        FROM student_food
        JOIN food ON food.id = student_food.food_id
        WHERE student_food.student_id = ?
        ORDER BY student_food.date DESC
      ''',
        [studentId],
      );
    } catch (e) {
      throw Exception("getStudentMealHistory failed: $e");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllStudentFoodRecords() async {
    try {
      final db = await database;
      return await db.rawQuery('''
        SELECT id, student_id, food_id, date
        FROM student_food
      ''');
    } catch (e) {
      throw Exception("getAllStudentFoodRecords failed: $e");
    }
  }

  @override
  Future<int> updateStudentRoom(int studentId, int? roomId) async {
    try {
      final db = await database;
      return await db.update(
        'student',
        {'room_id': roomId},
        where: 'id = ?',
        whereArgs: [studentId],
      );
    } catch (e) {
      throw Exception("updateStudentRoom failed: $e");
    }
  }
}

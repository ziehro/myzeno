import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:zeno/src/models/food_log.dart';
import 'package:zeno/src/models/activity_log.dart';
import 'package:zeno/src/models/weight_log.dart';
import 'package:zeno/src/models/user_profile.dart';
import 'package:zeno/src/models/user_goal.dart';
import 'package:zeno/src/services/subscription_service.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'zeno_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // User profile table
    await db.execute('''
      CREATE TABLE user_profile(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT UNIQUE,
        email TEXT,
        startWeight REAL,
        height REAL,
        age INTEGER,
        sex TEXT,
        createdAt TEXT,
        activityLevel TEXT
      )
    ''');

    // User goal table
    await db.execute('''
      CREATE TABLE user_goal(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lbsToLose REAL,
        days INTEGER
      )
    ''');

    // Food logs table
    await db.execute('''
      CREATE TABLE food_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        calories INTEGER,
        quantity INTEGER DEFAULT 1,
        date TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Activity logs table
    await db.execute('''
      CREATE TABLE activity_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        caloriesBurned INTEGER,
        quantity INTEGER DEFAULT 1,
        date TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Weight logs table
    await db.execute('''
      CREATE TABLE weight_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL,
        date TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Frequent items tables (for favorites)
    await db.execute('''
      CREATE TABLE frequent_foods(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE,
        calories INTEGER,
        usage_count INTEGER DEFAULT 1,
        last_used TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE frequent_activities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE,
        caloriesBurned INTEGER,
        usage_count INTEGER DEFAULT 1,
        last_used TEXT
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_food_logs_date ON food_logs(date)');
    await db.execute('CREATE INDEX idx_activity_logs_date ON activity_logs(date)');
    await db.execute('CREATE INDEX idx_weight_logs_date ON weight_logs(date)');
  }

  // --- USER PROFILE & GOAL METHODS ---
  Future<void> saveUserProfile(UserProfile profile) async {
    final db = await database;
    await db.insert(
      'user_profile',
      profile.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveUserGoal(UserGoal goal) async {
    final db = await database;
    await db.delete('user_goal'); // Only one goal at a time
    await db.insert('user_goal', goal.toJson());
  }

  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user_profile', limit: 1);
    if (maps.isNotEmpty) {
      return UserProfile.fromJson(maps.first);
    }
    return null;
  }

  Future<UserGoal?> getUserGoal() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user_goal', limit: 1);
    if (maps.isNotEmpty) {
      return UserGoal.fromJson(maps.first);
    }
    return null;
  }

  // --- FOOD LOG METHODS ---
  Future<int> addFoodLog(FoodLog log) async {
    final db = await database;
    final id = await db.insert('food_logs', {
      'name': log.name,
      'calories': log.calories,
      'quantity': log.quantity,
      'date': log.date.toIso8601String(),
    });

    // Update frequent foods
    await _updateFrequentFood(log.name, log.calories);
    return id;
  }

  Future<void> updateFoodLog(FoodLog log) async {
    final db = await database;
    await db.update(
      'food_logs',
      {
        'name': log.name,
        'calories': log.calories,
        'quantity': log.quantity,
        'date': log.date.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [int.parse(log.id)],
    );

    await _updateFrequentFood(log.name, log.calories);
  }

  Future<void> deleteFoodLog(String logId) async {
    final db = await database;
    await db.delete('food_logs', where: 'id = ?', whereArgs: [int.parse(logId)]);
  }

  Future<List<FoodLog>> getTodaysFoodLogs() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'food_logs',
      where: 'date >= ? AND date < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => FoodLog(
      id: map['id'].toString(),
      name: map['name'],
      calories: map['calories'],
      quantity: map['quantity'] ?? 1,
      date: DateTime.parse(map['date']),
    )).toList();
  }

  Future<List<FoodLog>> getRecentFoodLogs({int days = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    final List<Map<String, dynamic>> maps = await db.query(
      'food_logs',
      where: 'date >= ?',
      whereArgs: [cutoffDate.toIso8601String()],
      orderBy: 'created_at DESC',
      limit: 200,
    );

    return maps.map((map) => FoodLog(
      id: map['id'].toString(),
      name: map['name'],
      calories: map['calories'],
      quantity: map['quantity'] ?? 1,
      date: DateTime.parse(map['date']),
    )).toList();
  }

  // --- ACTIVITY LOG METHODS ---
  Future<int> addActivityLog(ActivityLog log) async {
    final db = await database;
    final id = await db.insert('activity_logs', {
      'name': log.name,
      'caloriesBurned': log.caloriesBurned,
      'quantity': log.quantity,
      'date': log.date.toIso8601String(),
    });

    await _updateFrequentActivity(log.name, log.caloriesBurned);
    return id;
  }

  Future<void> updateActivityLog(ActivityLog log) async {
    final db = await database;
    await db.update(
      'activity_logs',
      {
        'name': log.name,
        'caloriesBurned': log.caloriesBurned,
        'quantity': log.quantity,
        'date': log.date.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [int.parse(log.id)],
    );

    await _updateFrequentActivity(log.name, log.caloriesBurned);
  }

  Future<void> deleteActivityLog(String logId) async {
    final db = await database;
    await db.delete('activity_logs', where: 'id = ?', whereArgs: [int.parse(logId)]);
  }

  Future<List<ActivityLog>> getTodaysActivityLogs() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'activity_logs',
      where: 'date >= ? AND date < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => ActivityLog(
      id: map['id'].toString(),
      name: map['name'],
      caloriesBurned: map['caloriesBurned'],
      quantity: map['quantity'] ?? 1,
      date: DateTime.parse(map['date']),
    )).toList();
  }

  Future<List<ActivityLog>> getRecentActivityLogs({int days = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    final List<Map<String, dynamic>> maps = await db.query(
      'activity_logs',
      where: 'date >= ?',
      whereArgs: [cutoffDate.toIso8601String()],
      orderBy: 'created_at DESC',
      limit: 200,
    );

    return maps.map((map) => ActivityLog(
      id: map['id'].toString(),
      name: map['name'],
      caloriesBurned: map['caloriesBurned'],
      quantity: map['quantity'] ?? 1,
      date: DateTime.parse(map['date']),
    )).toList();
  }

  // --- WEIGHT LOG METHODS ---
  Future<int> addWeightLog(WeightLog log) async {
    final db = await database;
    return await db.insert('weight_logs', {
      'weight': log.weight,
      'date': log.date.toIso8601String(),
    });
  }

  Future<List<WeightLog>> getWeightLogs({int? limit}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'weight_logs',
      orderBy: 'date DESC',
      limit: limit,
    );

    return maps.map((map) => WeightLog(
      id: map['id'].toString(),
      weight: map['weight'],
      date: DateTime.parse(map['date']),
    )).toList();
  }

  // --- FREQUENT ITEMS METHODS ---
  Future<void> _updateFrequentFood(String name, int calories) async {
    final db = await database;
    final existing = await db.query(
      'frequent_foods',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (existing.isNotEmpty) {
      final currentCount = existing.first['usage_count'] as int;
      await db.update(
        'frequent_foods',
        {
          'usage_count': currentCount + 1,
          'last_used': DateTime.now().toIso8601String(),
        },
        where: 'name = ?',
        whereArgs: [name],
      );
    } else {
      await db.insert('frequent_foods', {
        'name': name,
        'calories': calories,
        'usage_count': 1,
        'last_used': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _updateFrequentActivity(String name, int caloriesBurned) async {
    final db = await database;
    final existing = await db.query(
      'frequent_activities',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (existing.isNotEmpty) {
      final currentCount = existing.first['usage_count'] as int;
      await db.update(
        'frequent_activities',
        {
          'usage_count': currentCount + 1,
          'last_used': DateTime.now().toIso8601String(),
        },
        where: 'name = ?',
        whereArgs: [name],
      );
    } else {
      await db.insert('frequent_activities', {
        'name': name,
        'caloriesBurned': caloriesBurned,
        'usage_count': 1,
        'last_used': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<FoodLog>> getFrequentFoodLogs() async {
    final db = await database;

    // Get subscription service to check limits
    final subscriptionService = SubscriptionService();
    final limit = subscriptionService.isPremium ? 50 : 10; // Premium gets 50, free gets 10

    final List<Map<String, dynamic>> maps = await db.query(
      'frequent_foods',
      orderBy: 'usage_count DESC, last_used DESC',
      limit: limit,
    );

    return maps.map((map) => FoodLog(
      id: map['id'].toString(),
      name: map['name'],
      calories: map['calories'],
      quantity: 1,
      date: DateTime.parse(map['last_used']),
    )).toList();
  }

  Future<List<ActivityLog>> getFrequentActivityLogs() async {
    final db = await database;

    // Get subscription service to check limits
    final subscriptionService = SubscriptionService();
    final limit = subscriptionService.isPremium ? 50 : 10; // Premium gets 50, free gets 10

    final List<Map<String, dynamic>> maps = await db.query(
      'frequent_activities',
      orderBy: 'usage_count DESC, last_used DESC',
      limit: limit,
    );

    return maps.map((map) => ActivityLog(
      id: map['id'].toString(),
      name: map['name'],
      caloriesBurned: map['caloriesBurned'],
      quantity: 1,
      date: DateTime.parse(map['last_used']),
    )).toList();
  }

  // --- DATA CLEANUP (for free version limits) ---
  Future<void> cleanupOldData({int keepDays = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));

    await db.delete(
      'food_logs',
      where: 'date < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );

    await db.delete(
      'activity_logs',
      where: 'date < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );

    // Keep more weight logs (they're smaller)
    final weightCutoff = DateTime.now().subtract(const Duration(days: 90));
    await db.delete(
      'weight_logs',
      where: 'date < ?',
      whereArgs: [weightCutoff.toIso8601String()],
    );
  }

  // --- EXPORT DATA (Premium feature) ---
  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;

    final profile = await getUserProfile();
    final goal = await getUserGoal();
    final foodLogs = await getRecentFoodLogs(days: 365);
    final activityLogs = await getRecentActivityLogs(days: 365);
    final weightLogs = await getWeightLogs();

    return {
      'profile': profile?.toJson(),
      'goal': goal?.toJson(),
      'foodLogs': foodLogs.map((log) => log.toJson()).toList(),
      'activityLogs': activityLogs.map((log) => log.toJson()).toList(),
      'weightLogs': weightLogs.map((log) => log.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  // --- DATABASE MANAGEMENT ---
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('user_profile');
    await db.delete('user_goal');
    await db.delete('food_logs');
    await db.delete('activity_logs');
    await db.delete('weight_logs');
    await db.delete('frequent_foods');
    await db.delete('frequent_activities');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
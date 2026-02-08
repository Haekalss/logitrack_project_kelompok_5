import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:kirimtrack/delivery_task_model.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService _instance = DatabaseService._internal();
  
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kirimtrack.db');

    return await openDatabase(
      path,
      version: 2, // Update version untuk migration
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Tabel untuk delivery tasks
    await db.execute('''
      CREATE TABLE delivery_tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        image_path TEXT,
        latitude REAL,
        longitude REAL,
        completed_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tabel untuk user profile
    await db.execute('''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone_number TEXT,
        profile_image_url TEXT,
        total_deliveries INTEGER NOT NULL DEFAULT 0,
        completed_deliveries INTEGER NOT NULL DEFAULT 0,
        rating REAL NOT NULL DEFAULT 0.0,
        join_date INTEGER NOT NULL,
        last_updated INTEGER NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tabel untuk settings
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Tabel untuk sync tracking
    await db.execute('''
      CREATE TABLE sync_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to delivery_tasks table
      await db.execute('ALTER TABLE delivery_tasks ADD COLUMN image_path TEXT');
      await db.execute('ALTER TABLE delivery_tasks ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE delivery_tasks ADD COLUMN longitude REAL');
      await db.execute('ALTER TABLE delivery_tasks ADD COLUMN completed_at INTEGER');
    }
  }

  // CRUD Operations untuk Delivery Tasks
  Future<void> insertTask(DeliveryTask task) async {
    final db = await database;
    await db.insert(
      'delivery_tasks',
      {
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'is_completed': task.isCompleted ? 1 : 0,
        'image_path': task.imagePath,
        'latitude': task.latitude,
        'longitude': task.longitude,
        'completed_at': task.completedAt?.millisecondsSinceEpoch,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _logSync(task.id, 'INSERT');
  }

  Future<void> updateTask(DeliveryTask task) async {
    final db = await database;
    await db.update(
      'delivery_tasks',
      {
        'title': task.title,
        'description': task.description,
        'is_completed': task.isCompleted ? 1 : 0,
        'image_path': task.imagePath,
        'latitude': task.latitude,
        'longitude': task.longitude,
        'completed_at': task.completedAt?.millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [task.id],
    );
    await _logSync(task.id, 'UPDATE');
  }

  Future<void> deleteTask(String taskId) async {
    final db = await database;
    await db.delete(
      'delivery_tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
    await _logSync(taskId, 'DELETE');
  }

  Future<List<DeliveryTask>> getAllTasks() async {
    final db = await database;
    final maps = await db.query('delivery_tasks', orderBy: 'created_at DESC');
    
    return maps.map((map) => DeliveryTask(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      isCompleted: (map['is_completed'] as int) == 1,
      imagePath: map['image_path'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      completedAt: map['completed_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
          : null,
    )).toList();
  }

  Future<DeliveryTask?> getTaskById(String taskId) async {
    final db = await database;
    final maps = await db.query(
      'delivery_tasks',
      where: 'id = ?',
      whereArgs: [taskId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    
    final map = maps.first;
    return DeliveryTask(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      isCompleted: (map['is_completed'] as int) == 1,
      imagePath: map['image_path'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      completedAt: map['completed_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
          : null,
    );
  }

  // Sync Management
  Future<List<Map<String, dynamic>>> getUnsyncedTasks() async {
    final db = await database;
    return await db.query(
      'delivery_tasks',
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  Future<void> markTaskAsSynced(String taskId) async {
    final db = await database;
    await db.update(
      'delivery_tasks',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> _logSync(String entityId, String action, {String entityType = 'delivery_task'}) async {
    final db = await database;
    await db.insert('sync_log', {
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'synced': 0,
    });
  }

  // USER PROFILE OPERATIONS
  Future<void> insertOrUpdateProfile(Map<String, dynamic> profileData) async {
    final db = await database;
    
    // Support both camelCase (from toJson) and snake_case keys
    final joinDateRaw = profileData['join_date'] ?? profileData['joinDate'];
    int joinDateMs;
    if (joinDateRaw is int) {
      joinDateMs = joinDateRaw;
    } else if (joinDateRaw is String) {
      joinDateMs = DateTime.parse(joinDateRaw).millisecondsSinceEpoch;
    } else {
      joinDateMs = DateTime.now().millisecondsSinceEpoch;
    }

    await db.insert(
      'user_profile',
      {
        'id': profileData['id'],
        'name': profileData['name'],
        'email': profileData['email'],
        'phone_number': profileData['phone_number'] ?? profileData['phoneNumber'],
        'profile_image_url': profileData['profile_image_url'] ?? profileData['profileImageUrl'],
        'total_deliveries': profileData['total_deliveries'] ?? profileData['totalDeliveries'] ?? 0,
        'completed_deliveries': profileData['completed_deliveries'] ?? profileData['completedDeliveries'] ?? 0,
        'rating': profileData['rating'] ?? 0.0,
        'join_date': joinDateMs,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _logSync(profileData['id'], 'UPSERT', entityType: 'user_profile');
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final db = await database;
    final maps = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<void> updateProfileStats(String userId, {int? totalDeliveries, int? completedDeliveries, double? rating}) async {
    final db = await database;
    final updateData = <String, dynamic>{
      'last_updated': DateTime.now().millisecondsSinceEpoch,
      'synced': 0,
    };
    
    if (totalDeliveries != null) updateData['total_deliveries'] = totalDeliveries;
    if (completedDeliveries != null) updateData['completed_deliveries'] = completedDeliveries;
    if (rating != null) updateData['rating'] = rating;

    await db.update(
      'user_profile',
      updateData,
      where: 'id = ?',
      whereArgs: [userId],
    );
    await _logSync(userId, 'UPDATE', entityType: 'user_profile');
  }

  // APP SETTINGS OPERATIONS
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  Future<bool> getBoolSetting(String key, {bool defaultValue = false}) async {
    final value = await getSetting(key);
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true';
  }

  Future<void> setBoolSetting(String key, bool value) async {
    await setSetting(key, value.toString());
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('delivery_tasks');
    await db.delete('user_profile');
    await db.delete('app_settings');
    await db.delete('sync_log');
  }
}
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../models/vehicle_data.dart';

/// SQLite database for trip logging and telemetry history.
///
/// Schema is set up now for future trip recording and CSV/JSON export.
class DatabaseService {
  static Database? _db;

  static const _dbName = 'dashburdz.db';
  static const _dbVersion = 1;

  // ── Table names ──
  static const tableTrips = 'trips';
  static const tableTelemetry = 'telemetry';

  /// Get (or lazily create) the database instance.
  static Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // ── Trips table ──
    await db.execute('''
      CREATE TABLE $tableTrips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        distance_km REAL DEFAULT 0,
        max_speed REAL DEFAULT 0,
        max_rpm REAL DEFAULT 0,
        avg_speed REAL DEFAULT 0,
        notes TEXT
      )
    ''');

    // ── Telemetry samples table ──
    await db.execute('''
      CREATE TABLE $tableTelemetry (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        rpm REAL NOT NULL,
        speed REAL NOT NULL,
        engine_oil_temp REAL NOT NULL,
        throttle_position REAL NOT NULL,
        intake_air_temp REAL NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES $tableTrips(id) ON DELETE CASCADE
      )
    ''');

    // Index for efficient trip-based queries
    await db.execute('''
      CREATE INDEX idx_telemetry_trip ON $tableTelemetry(trip_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_telemetry_time ON $tableTelemetry(timestamp)
    ''');
  }

  // ── Trip Operations ──

  /// Start a new trip. Returns the trip ID.
  static Future<int> startTrip() async {
    final db = await database;
    return db.insert(tableTrips, {
      'start_time': DateTime.now().toIso8601String(),
    });
  }

  /// End an active trip.
  static Future<void> endTrip(int tripId, {String? notes}) async {
    final db = await database;
    await db.update(
      tableTrips,
      {
        'end_time': DateTime.now().toIso8601String(),
        if (notes != null) 'notes': notes,
      },
      where: 'id = ?',
      whereArgs: [tripId],
    );
  }

  /// Record a telemetry sample for a trip.
  static Future<void> recordSample(int tripId, VehicleData data) async {
    final db = await database;
    await db.insert(tableTelemetry, {
      'trip_id': tripId,
      'timestamp': data.timestamp.toIso8601String(),
      'rpm': data.rpm,
      'speed': data.speed,
      'engine_oil_temp': data.engineOilTemp,
      'throttle_position': data.throttlePosition,
      'intake_air_temp': data.intakeAirTemp,
    });
  }

  /// Get all trips, newest first.
  static Future<List<Map<String, dynamic>>> getTrips() async {
    final db = await database;
    return db.query(tableTrips, orderBy: 'start_time DESC');
  }

  /// Get all telemetry samples for a trip.
  static Future<List<Map<String, dynamic>>> getTripTelemetry(int tripId) async {
    final db = await database;
    return db.query(
      tableTelemetry,
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'timestamp ASC',
    );
  }

  /// Delete a trip and all its telemetry.
  static Future<void> deleteTrip(int tripId) async {
    final db = await database;
    await db.delete(tableTrips, where: 'id = ?', whereArgs: [tripId]);
  }

  /// Close the database.
  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

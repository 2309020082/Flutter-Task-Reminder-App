import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Tugas {
  final int? id;
  final String namaTugas;
  final String mataKuliah;
  final String deadline;
  final String prioritas; // Tinggi, Sedang, Rendah
  final String status; // Belum Selesai, Selesai
  final String deskripsi;

  Tugas({
    this.id,
    required this.namaTugas,
    required this.mataKuliah,
    required this.deadline,
    required this.prioritas,
    this.status = 'Belum Selesai',
    this.deskripsi = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'namaTugas': namaTugas,
      'mataKuliah': mataKuliah,
      'deadline': deadline,
      'prioritas': prioritas,
      'status': status,
      'deskripsi': deskripsi,
    };
  }

  factory Tugas.fromMap(Map<String, dynamic> map) {
    return Tugas(
      id: map['id'],
      namaTugas: map['namaTugas'],
      mataKuliah: map['mataKuliah'],
      deadline: map['deadline'],
      prioritas: map['prioritas'],
      status: map['status'] ?? 'Belum Selesai',
      deskripsi: map['deskripsi'] ?? '',
    );
  }

  Tugas copyWith({
    int? id,
    String? namaTugas,
    String? mataKuliah,
    String? deadline,
    String? prioritas,
    String? status,
    String? deskripsi,
  }) {
    return Tugas(
      id: id ?? this.id,
      namaTugas: namaTugas ?? this.namaTugas,
      mataKuliah: mataKuliah ?? this.mataKuliah,
      deadline: deadline ?? this.deadline,
      prioritas: prioritas ?? this.prioritas,
      status: status ?? this.status,
      deskripsi: deskripsi ?? this.deskripsi,
    );
  }
}

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tugas_kuliah.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tugas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        namaTugas TEXT NOT NULL,
        mataKuliah TEXT NOT NULL,
        deadline TEXT NOT NULL,
        prioritas TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Belum Selesai',
        deskripsi TEXT DEFAULT ''
      )
    ''');
  }

  Future<int> insertTugas(Tugas tugas) async {
    final db = await database;
    return await db.insert('tugas', tugas.toMap());
  }

  Future<List<Tugas>> getAllTugas() async {
    final db = await database;
    final maps = await db.query('tugas', orderBy: 'deadline ASC');
    return maps.map((map) => Tugas.fromMap(map)).toList();
  }

  Future<List<Tugas>> getTugasByMataKuliah(String mataKuliah) async {
    final db = await database;
    final maps = await db.query(
      'tugas',
      where: 'mataKuliah = ?',
      whereArgs: [mataKuliah],
      orderBy: 'deadline ASC',
    );
    return maps.map((map) => Tugas.fromMap(map)).toList();
  }

  Future<List<Tugas>> getTugasByDeadlineDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'tugas',
      where: 'deadline LIKE ?',
      whereArgs: ['$date%'],
      orderBy: 'deadline ASC',
    );
    return maps.map((map) => Tugas.fromMap(map)).toList();
  }

  Future<int> updateTugas(Tugas tugas) async {
    final db = await database;
    return await db.update(
      'tugas',
      tugas.toMap(),
      where: 'id = ?',
      whereArgs: [tugas.id],
    );
  }

  Future<int> deleteTugas(int id) async {
    final db = await database;
    return await db.delete('tugas', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> getAllMataKuliah() async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT DISTINCT mataKuliah FROM tugas ORDER BY mataKuliah ASC',
    );
    return maps.map((m) => m['mataKuliah'] as String).toList();
  }

  Future<Map<String, int>> getTugasPerMataKuliah() async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT mataKuliah, COUNT(*) as count FROM tugas GROUP BY mataKuliah',
    );
    return {for (var m in maps) m['mataKuliah'] as String: m['count'] as int};
  }
}
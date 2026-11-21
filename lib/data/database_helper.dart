import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Pembuka basis data SQLite untuk fitur Campus Report.
///
/// Berkas basis data disimpan di direktori aplikasi, jadi ikut terhapus bila
/// aplikasi dihapus. Saat skema berubah, naikkan [versiBasisData] supaya
/// onCreate dijalankan kembali atau migrasinya ditangani di onUpgrade.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String namaBasisData = 'campus_report.db';
  static const int versiBasisData = 1;
  static const String tabelReports = 'reports';

  Database? _basisData;

  Future<Database> get database async => _basisData ??= await _buka();

  Future<Database> _buka() async {
    final folder = await getDatabasesPath();
    return openDatabase(
      p.join(folder, namaBasisData),
      version: versiBasisData,
      onCreate: _buatSkema,
      onUpgrade: _naikkanVersi,
    );
  }

  Future<void> _buatSkema(Database db, int versi) async {
    await db.execute('''
      CREATE TABLE $tabelReports (
        local_id     TEXT PRIMARY KEY,
        title        TEXT NOT NULL,
        category     TEXT NOT NULL,
        description  TEXT NOT NULL,
        priority     TEXT NOT NULL DEFAULT 'sedang',
        created_at   TEXT NOT NULL,
        photo_path   TEXT,
        latitude     REAL,
        longitude    REAL,
        status       TEXT NOT NULL DEFAULT 'DRAFT',
        server_id    TEXT,
        last_error   TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_reports_status ON $tabelReports(status)',
    );
    await db.execute(
      'CREATE INDEX idx_reports_created ON $tabelReports(created_at DESC)',
    );
  }

  Future<void> _naikkanVersi(Database db, int versiLama, int versiBaru) async {
    // Belum ada migrasi. Kolom baru ditambahkan di sini saat skema berubah.
  }

  Future<void> tutup() async {
    await _basisData?.close();
    _basisData = null;
  }
}

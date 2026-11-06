import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Pembungkus tunggal (singleton) untuk file database `studylog.db`.
///
/// Kelas ini hanya tahu soal koneksi dan skema. Ia tidak tahu apa pun
/// tentang UI, dan tidak menjalankan operasi CRUD — itu tugas
/// `CatatanRepository`.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _namaDatabase = 'studylog.db';
  static const _versiDatabase = 1;
  static const tabelCatatan = 'catatan';

  Database? _database;

  /// Membuka database sekali saja, lalu memakai koneksi yang sama
  /// untuk pemanggilan berikutnya.
  Future<Database> get database async {
    final tersimpan = _database;
    if (tersimpan != null) return tersimpan;

    final dibuka = await _buka();
    _database = dibuka;
    return dibuka;
  }

  Future<Database> _buka() async {
    final folder = await getDatabasesPath();
    final lokasi = join(folder, _namaDatabase);

    return openDatabase(
      lokasi,
      version: _versiDatabase,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _buatSkema,
    );
  }

  /// Skema dibuat satu kali saat file database pertama kali dibuka.
  /// Perubahan kolom setelah aplikasi terpasang memerlukan strategi
  /// migrasi lewat `onUpgrade`, bukan sekadar mengubah kode di sini.
  Future<void> _buatSkema(Database db, int versi) async {
    await db.execute('''
      CREATE TABLE $tabelCatatan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mata_kuliah TEXT NOT NULL,
        judul TEXT NOT NULL,
        isi TEXT NOT NULL,
        tanggal TEXT NOT NULL
      )
    ''');
  }

  /// Menutup koneksi. Dipakai pada pengujian dan saat data perlu
  /// dipastikan benar-benar ditulis ke disk.
  Future<void> tutup() async {
    final tersimpan = _database;
    if (tersimpan == null) return;
    await tersimpan.close();
    _database = null;
  }

  /// Menghapus file database. Berguna saat pengujian atau reset data.
  Future<void> hapusDatabase() async {
    await tutup();
    final folder = await getDatabasesPath();
    await deleteDatabase(join(folder, _namaDatabase));
  }
}
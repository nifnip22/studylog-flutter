import 'package:sqflite/sqflite.dart';

import '../models/catatan.dart';
import 'database_helper.dart';

/// Satu-satunya pintu antara aplikasi dan tabel `catatan`.
///
/// Lapisan UI dan ViewModel tidak pernah menulis SQL. Semua perintah
/// SQL terkumpul di sini, dan setiap parameter yang berasal dari luar
/// dikirim lewat `whereArgs` — bukan disambung ke dalam string query.
class CatatanRepository {
  CatatanRepository({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  Future<Database> get _db => _helper.database;

  /// Semua catatan, terbaru lebih dulu.
  Future<List<Catatan>> semua() async {
    final db = await _db;
    final baris = await db.query(
      DatabaseHelper.tabelCatatan,
      orderBy: 'tanggal DESC, id DESC',
    );
    return baris.map(Catatan.fromMap).toList();
  }

  /// Menyimpan catatan baru dan mengembalikan id hasil AUTOINCREMENT.
  Future<int> tambah(Catatan catatan) async {
    final db = await _db;
    final peta = catatan.toMap()..remove('id');
    return db.insert(DatabaseHelper.tabelCatatan, peta);
  }

  /// Memperbarui satu baris berdasarkan id. Mengembalikan jumlah baris
  /// yang benar-benar berubah (0 berarti id tidak ditemukan).
  Future<int> ubah(Catatan catatan) async {
    final id = catatan.id;
    if (id == null) {
      throw ArgumentError('Catatan tanpa id tidak dapat diubah');
    }

    final db = await _db;
    return db.update(
      DatabaseHelper.tabelCatatan,
      catatan.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Menghapus satu baris berdasarkan id. Mengembalikan jumlah baris
  /// yang terhapus.
  Future<int> hapus(int id) async {
    final db = await _db;
    return db.delete(
      DatabaseHelper.tabelCatatan,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Membaca satu catatan; `null` bila id tidak ada.
  Future<Catatan?> cariBerdasarkanId(int id) async {
    final db = await _db;
    final baris = await db.query(
      DatabaseHelper.tabelCatatan,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (baris.isEmpty) return null;
    return Catatan.fromMap(baris.first);
  }
}
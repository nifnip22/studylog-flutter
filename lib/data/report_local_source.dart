import 'package:sqflite/sqflite.dart';

import '../models/laporan.dart';
import 'database_helper.dart';

/// Abstraksi penyimpanan lokal. Repositori hanya berbicara lewat kontrak ini,
/// sehingga pengujian bisa memakai versi in-memory tanpa emulator.
abstract class ReportLocalSource {
  Future<void> simpan(Laporan laporan);

  Future<List<Laporan>> semua();

  Future<Laporan?> cari(String localId);

  Future<List<Laporan>> antrean();

  Future<void> ubahStatus(
    String localId,
    StatusSinkronisasi status, {
    String? serverId,
    String? lastError,
    bool hapusError = false,
  });

  Future<void> hapus(String localId);

  /// Mengubah laporan yang tertinggal di status SENDING menjadi FAILED.
  /// Dijalankan sekali setiap aplikasi dibuka.
  Future<int> pulihkanStatusSending();
}

class SqliteReportLocalSource implements ReportLocalSource {
  SqliteReportLocalSource({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  static const String _tabel = DatabaseHelper.tabelReports;

  @override
  Future<void> simpan(Laporan laporan) async {
    final db = await _helper.database;
    await db.insert(
      _tabel,
      laporan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Laporan>> semua() async {
    final db = await _helper.database;
    final baris = await db.query(_tabel, orderBy: 'created_at DESC');
    return baris.map(Laporan.fromMap).toList(growable: false);
  }

  @override
  Future<Laporan?> cari(String localId) async {
    final db = await _helper.database;
    final baris = await db.query(
      _tabel,
      where: 'local_id = ?',
      whereArgs: [localId],
      limit: 1,
    );
    if (baris.isEmpty) return null;
    return Laporan.fromMap(baris.first);
  }

  @override
  Future<List<Laporan>> antrean() async {
    final db = await _helper.database;
    final baris = await db.query(
      _tabel,
      where: 'status IN (?, ?)',
      whereArgs: [
        StatusSinkronisasi.pending.label,
        StatusSinkronisasi.failed.label,
      ],
      orderBy: 'created_at ASC',
    );
    return baris.map(Laporan.fromMap).toList(growable: false);
  }

  @override
  Future<void> ubahStatus(
    String localId,
    StatusSinkronisasi status, {
    String? serverId,
    String? lastError,
    bool hapusError = false,
  }) async {
    final db = await _helper.database;
    await db.update(
      _tabel,
      <String, Object?>{
        'status': status.label,
        if (serverId != null) 'server_id': serverId,
        if (hapusError) 'last_error': null,
        if (!hapusError && lastError != null) 'last_error': lastError,
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  @override
  Future<void> hapus(String localId) async {
    final db = await _helper.database;
    await db.delete(_tabel, where: 'local_id = ?', whereArgs: [localId]);
  }

  @override
  Future<int> pulihkanStatusSending() async {
    final db = await _helper.database;
    return db.update(
      _tabel,
      <String, Object?>{
        'status': StatusSinkronisasi.failed.label,
        'last_error':
            'Pengiriman terputus: aplikasi berhenti saat status SENDING',
      },
      where: 'status = ?',
      whereArgs: [StatusSinkronisasi.sending.label],
    );
  }
}

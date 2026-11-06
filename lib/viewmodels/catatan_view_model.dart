import 'package:flutter/foundation.dart';

import '../data/catatan_repository.dart';
import '../models/catatan.dart';

/// Menyimpan keadaan daftar catatan untuk dibaca UI.
///
/// Aturan yang dipegang: setiap operasi tulis diikuti [muatUlang], jadi
/// apa yang tampil di layar selalu berasal dari isi database, bukan dari
/// salinan di memori.
class CatatanViewModel extends ChangeNotifier {
  CatatanViewModel({CatatanRepository? repository})
      : _repository = repository ?? CatatanRepository();

  final CatatanRepository _repository;

  List<Catatan> _daftar = const [];
  bool _isLoading = false;
  String? _error;

  List<Catatan> get daftar => List.unmodifiable(_daftar);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get kosong => !_isLoading && _error == null && _daftar.isEmpty;

  /// Memuat ulang seluruh daftar dari database.
  Future<void> muatUlang() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _daftar = await _repository.semua();
    } catch (e) {
      _error = 'Gagal memuat catatan: $e';
      _daftar = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Menambah catatan, lalu memuat ulang daftar.
  Future<bool> tambah(Catatan catatan) async {
    return _jalankan(() async {
      await _repository.tambah(catatan);
    }, pesanGagal: 'Gagal menambah catatan');
  }

  /// Mengubah catatan, lalu memuat ulang daftar.
  Future<bool> ubah(Catatan catatan) async {
    return _jalankan(() async {
      await _repository.ubah(catatan);
    }, pesanGagal: 'Gagal mengubah catatan');
  }

  /// Menghapus catatan, lalu memuat ulang daftar.
  Future<bool> hapus(int id) async {
    return _jalankan(() async {
      await _repository.hapus(id);
    }, pesanGagal: 'Gagal menghapus catatan');
  }

  /// Satu jalur untuk semua operasi tulis: tandai memuat, jalankan,
  /// tangkap error, muat ulang dari database.
  Future<bool> _jalankan(
    Future<void> Function() operasi, {
    required String pesanGagal,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await operasi();
      _daftar = await _repository.semua();
      return true;
    } catch (e) {
      _error = '$pesanGagal: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
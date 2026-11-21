import 'package:flutter/foundation.dart';

import '../data/report_repository.dart';
import '../models/laporan.dart';
import '../services/lokasi_service.dart';

/// State dan perintah untuk seluruh layar Campus Report.
///
/// Layar hanya membaca [daftar], [memuat], dan [pesan], lalu memanggil
/// perintah di kelas ini. Tidak ada layar yang menyentuh SQLite atau HTTP.
class LaporanViewModel extends ChangeNotifier {
  LaporanViewModel(this._repository);

  final ReportRepository _repository;

  List<Laporan> _daftar = const <Laporan>[];
  bool _memuat = false;
  String? _pesan;

  List<Laporan> get daftar => List<Laporan>.unmodifiable(_daftar);
  bool get memuat => _memuat;
  String? get pesan => _pesan;

  int get jumlahDraft =>
      _daftar.where((l) => l.status == StatusSinkronisasi.draft).length;
  int get jumlahGagal =>
      _daftar.where((l) => l.status == StatusSinkronisasi.failed).length;

  Future<void> muat() async {
    _memuat = true;
    notifyListeners();

    await _repository.pulihkanStatusTertinggal();
    _daftar = await _repository.daftar();

    _memuat = false;
    notifyListeners();
  }

  void bersihkanPesan() {
    _pesan = null;
    notifyListeners();
  }

  Future<String?> ambilFoto(String localId) => _repository.ambilFoto(localId);

  Future<HasilLokasi> ambilLokasi() => _repository.ambilLokasi();

  Future<void> simpan(Laporan laporan, {required bool langsungKirim}) async {
    await _repository.simpanDraft(laporan);

    if (langsungKirim) {
      await _repository.antrekan(laporan.localId);
      final hasil = await _repository.kirim(laporan.localId);
      _pesan = hasil.berhasil
          ? 'Laporan terkirim ke server.'
          : 'Gagal kirim: ${hasil.pesan}';
    } else {
      _pesan = 'Draft tersimpan di perangkat.';
    }
    await muat();
  }

  Future<void> kirimUlang(String localId) async {
    _memuat = true;
    notifyListeners();

    await _repository.antrekan(localId);
    final hasil = await _repository.kirim(localId);
    _pesan = hasil.berhasil
        ? 'Laporan berhasil dikirim.'
        : 'Gagal kirim: ${hasil.pesan}';

    await muat();
  }

  Future<void> kirimSemuaAntrean() async {
    _memuat = true;
    notifyListeners();

    _daftar = await _repository.kirimAntrean();
    _pesan = 'Antrean selesai diproses.';

    _memuat = false;
    await muat();
  }

  Future<void> hapus(String localId) async {
    await _repository.hapus(localId);
    _pesan = 'Laporan dihapus dari perangkat.';
    await muat();
  }
}

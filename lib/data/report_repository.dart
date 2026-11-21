import '../models/laporan.dart';
import '../services/api_service.dart';
import '../services/foto_service.dart';
import '../services/lokasi_service.dart';
import 'report_local_source.dart';

/// Inti pola offline-first.
///
/// Semua penulisan selalu masuk SQLite lebih dahulu, baru kemudian dikirim ke
/// API. Perubahan status, pengiriman ulang, dan pemulihan status SENDING yang
/// tertinggal semuanya dikumpulkan di kelas ini supaya lapisan layar tidak
/// perlu tahu apa-apa soal jaringan.
class ReportRepository {
  ReportRepository({
    ReportLocalSource? local,
    ApiService? api,
    FotoService? foto,
    LokasiService? lokasi,
  })  : _local = local ?? SqliteReportLocalSource(),
        _api = api ?? ApiService(),
        _foto = foto ?? FotoService(),
        _lokasi = lokasi ?? LokasiService();

  final ReportLocalSource _local;
  final ApiService _api;
  final FotoService _foto;
  final LokasiService _lokasi;

  /// Dipanggil sekali saat aplikasi dibuka, sebelum daftar laporan dimuat.
  Future<int> pulihkanStatusTertinggal() => _local.pulihkanStatusSending();

  Future<List<Laporan>> daftar() => _local.semua();

  Future<Laporan?> cari(String localId) => _local.cari(localId);

  Future<String?> ambilFoto(String localId) => _foto.ambilFoto(localId);

  Future<HasilLokasi> ambilLokasi() => _lokasi.ambilLokasi();

  Future<void> simpanDraft(Laporan laporan) => _local.simpan(laporan);

  Future<void> ubahDraft(Laporan laporan) => _local.simpan(laporan);

  Future<void> antrekan(String localId) => _local.ubahStatus(
        localId,
        StatusSinkronisasi.pending,
        hapusError: true,
      );

  Future<void> hapus(String localId) async {
    final laporan = await _local.cari(localId);
    await _foto.hapusFoto(laporan?.photoPath);
    await _local.hapus(localId);
  }

  /// Mengirim satu laporan memakai clientReportId yang sudah dimilikinya.
  /// Mengirim ulang laporan yang sama tidak akan membuat entri baru di server.
  Future<HasilKirim> kirim(String localId) async {
    final laporan = await _local.cari(localId);
    if (laporan == null) {
      return const HasilKirim.gagal(
        'Laporan tidak ditemukan di penyimpanan lokal.',
      );
    }

    await _local.ubahStatus(
      localId,
      StatusSinkronisasi.sending,
      hapusError: true,
    );

    final base64 = await _foto.keBase64(laporan.photoPath);
    final hasil = await _api.kirim(laporan, photoBase64: base64);

    if (hasil.berhasil) {
      await _local.ubahStatus(
        localId,
        StatusSinkronisasi.success,
        serverId: hasil.serverId,
        hapusError: true,
      );
    } else {
      await _local.ubahStatus(
        localId,
        StatusSinkronisasi.failed,
        lastError: hasil.pesan,
      );
    }
    return hasil;
  }

  /// Mengirim seluruh antrean (PENDING dan FAILED) satu per satu.
  Future<List<Laporan>> kirimAntrean() async {
    final isiAntrean = await _local.antrean();
    for (final laporan in isiAntrean) {
      await kirim(laporan.localId);
    }
    return _local.semua();
  }
}

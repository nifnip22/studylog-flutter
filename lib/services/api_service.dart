import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/laporan.dart';

/// Hasil satu percobaan pengiriman laporan ke API.
class HasilKirim {
  const HasilKirim.sukses(String this.serverId, {this.duplikat = false})
      : pesan = null,
        berhasil = true;

  const HasilKirim.gagal(String this.pesan)
      : serverId = null,
        duplikat = false,
        berhasil = false;

  final bool berhasil;
  final String? serverId;
  final String? pesan;
  final bool duplikat;
}

/// Klien REST untuk backend demo Campus Report.
///
/// Alamat dasar bisa ditimpa lewat --dart-define=API_BASE_URL=...
/// Nilai bawaan 10.0.2.2 adalah alias host dari dalam emulator Android.
class ApiService {
  ApiService({
    http.Client? klien,
    String? alamatDasar,
    this.batasWaktu = const Duration(seconds: 10),
  })  : _klien = klien ?? http.Client(),
        alamatDasar = alamatDasar ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8000',
            );

  final http.Client _klien;
  final String alamatDasar;
  final Duration batasWaktu;

  Uri get _endpoint => Uri.parse('$alamatDasar/reports');

  Uri get _health => Uri.parse('$alamatDasar/health');

  Future<bool> sehat() async {
    try {
      final respons = await _klien.get(_health).timeout(batasWaktu);
      return respons.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<HasilKirim> kirim(Laporan laporan, {String? photoBase64}) async {
    try {
      final respons = await _klien
          .post(
            _endpoint,
            headers: const <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonEncode(laporan.toJsonBody(photoBase64: photoBase64)),
          )
          .timeout(batasWaktu);

      if (respons.statusCode == 201 || respons.statusCode == 200) {
        final isi = jsonDecode(respons.body) as Map<String, Object?>;
        return HasilKirim.sukses(
          (isi['serverId'] as String?) ?? '-',
          duplikat: respons.statusCode == 200,
        );
      }
      return HasilKirim.gagal(
        'Server menolak (${respons.statusCode}): ${_ringkas(respons.body)}',
      );
    } on TimeoutException {
      return const HasilKirim.gagal(
        'Batas waktu terlampaui. Laporan tetap tersimpan dan bisa dikirim ulang.',
      );
    } catch (galat) {
      return HasilKirim.gagal(
        'Koneksi gagal: $galat. Laporan tetap tersimpan dan bisa dikirim ulang.',
      );
    }
  }

  String _ringkas(String badan) =>
      badan.length > 160 ? '${badan.substring(0, 160)}...' : badan;
}

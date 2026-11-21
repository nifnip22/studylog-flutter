import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studylog_flutter/data/report_local_source.dart';
import 'package:studylog_flutter/data/report_repository.dart';
import 'package:studylog_flutter/models/laporan.dart';
import 'package:studylog_flutter/services/api_service.dart';

/// Penyimpanan in-memory untuk pengujian. Dipakai supaya logika repositori
/// bisa diuji tanpa emulator dan tanpa sqflite.
class MemoriReportLocalSource implements ReportLocalSource {
  final Map<String, Laporan> isi = <String, Laporan>{};

  @override
  Future<void> simpan(Laporan laporan) async {
    isi[laporan.localId] = laporan;
  }

  @override
  Future<List<Laporan>> semua() async {
    final daftar = isi.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return daftar;
  }

  @override
  Future<Laporan?> cari(String localId) async => isi[localId];

  @override
  Future<List<Laporan>> antrean() async =>
      isi.values.where((l) => l.status.perluDikirim).toList();

  @override
  Future<void> ubahStatus(
    String localId,
    StatusSinkronisasi status, {
    String? serverId,
    String? lastError,
    bool hapusError = false,
  }) async {
    final Laporan? laporan = isi[localId];
    if (laporan == null) return;
    isi[localId] = laporan.copyWith(
      status: status,
      serverId: serverId,
      lastError: lastError,
      hapusError: hapusError,
    );
  }

  @override
  Future<void> hapus(String localId) async {
    isi.remove(localId);
  }

  @override
  Future<int> pulihkanStatusSending() async {
    var jumlah = 0;
    for (final Laporan laporan in isi.values.toList()) {
      if (laporan.status == StatusSinkronisasi.sending) {
        isi[laporan.localId] = laporan.copyWith(
          status: StatusSinkronisasi.failed,
          lastError: 'Pengiriman terputus karena aplikasi berhenti',
        );
        jumlah++;
      }
    }
    return jumlah;
  }
}

Laporan laporanContoh() => Laporan.baru(
      title: 'AC ruang IFB5A mati',
      category: 'Pendingin Ruangan',
      description: 'AC menyala tetapi tidak mengeluarkan udara dingin sejak pagi.',
      priority: 'tinggi',
    );

void main() {
  group('Model laporan', () {
    test('bolak-balik lewat map SQLite tetap utuh', () {
      final asal = laporanContoh().copyWith(
        photoPath: '/data/laporan_uji.jpg',
        latitude: -1.2549459,
        longitude: 116.9137987,
        status: StatusSinkronisasi.success,
        serverId: 'SRV-000001',
      );

      final hasil = Laporan.fromMap(asal.toMap());

      expect(hasil.localId, asal.localId);
      expect(hasil.title, asal.title);
      expect(hasil.category, asal.category);
      expect(hasil.description, asal.description);
      expect(hasil.priority, asal.priority);
      expect(hasil.photoPath, asal.photoPath);
      expect(hasil.latitude, closeTo(asal.latitude!, 0.0000001));
      expect(hasil.longitude, closeTo(asal.longitude!, 0.0000001));
      expect(hasil.status, StatusSinkronisasi.success);
      expect(hasil.serverId, 'SRV-000001');
    });

    test('getId permintaan memakai clientReportId yang sama dengan localId', () {
      final laporan = laporanContoh();
      final badan = laporan.toJsonBody();

      expect(badan['clientReportId'], laporan.localId);
      expect(badan.containsKey('latitude'), isFalse);
      expect(badan.containsKey('photoBase64'), isFalse);
    });

    test('status tidak dikenal jatuh kembali ke DRAFT', () {
      final peta = laporanContoh().toMap()..['status'] = 'ENTAH';
      expect(Laporan.fromMap(peta).status, StatusSinkronisasi.draft);
    });
  });

  group('Repositori dan siklus status', () {
    late MemoriReportLocalSource lokal;
    late List<Map<String, Object?>> badanTerkirim;

    ReportRepository repositoriDengan(
      Future<http.Response> Function(http.Request) balasan,
    ) {
      lokal = MemoriReportLocalSource();
      badanTerkirim = <Map<String, Object?>>[];
      return ReportRepository(
        local: lokal,
        api: ApiService(
          alamatDasar: 'http://uji.local',
          klien: MockClient((http.Request permintaan) async {
            badanTerkirim.add(
              jsonDecode(permintaan.body) as Map<String, Object?>,
            );
            return balasan(permintaan);
          }),
        ),
      );
    }

    test('draft disimpan lokal dengan status DRAFT', () async {
      final repo = repositoriDengan(
        (_) async => http.Response('{}', 201),
      );
      final laporan = laporanContoh();

      await repo.simpanDraft(laporan);

      final tersimpan = await repo.cari(laporan.localId);
      expect(tersimpan, isNotNull);
      expect(tersimpan!.status, StatusSinkronisasi.draft);
    });

    test('respons 201 membuat status SUCCESS dan menyimpan serverId', () async {
      final repo = repositoriDengan(
        (_) async => http.Response(
          jsonEncode(<String, Object?>{
            'serverId': 'SRV-000123',
            'clientReportId': 'x',
          }),
          201,
        ),
      );
      final laporan = laporanContoh();
      await repo.simpanDraft(laporan);

      final hasil = await repo.kirim(laporan.localId);

      expect(hasil.berhasil, isTrue);
      expect(hasil.serverId, 'SRV-000123');
      final tersimpan = await repo.cari(laporan.localId);
      expect(tersimpan!.status, StatusSinkronisasi.success);
      expect(tersimpan.serverId, 'SRV-000123');
    });

    test('respons 500 membuat status FAILED tanpa menghapus data', () async {
      final repo = repositoriDengan(
        (_) async => http.Response('{"error":"server tumbang"}', 500),
      );
      final laporan = laporanContoh();
      await repo.simpanDraft(laporan);

      final hasil = await repo.kirim(laporan.localId);

      expect(hasil.berhasil, isFalse);
      final tersimpan = await repo.cari(laporan.localId);
      expect(tersimpan, isNotNull);
      expect(tersimpan!.status, StatusSinkronisasi.failed);
      expect(tersimpan.lastError, contains('500'));
      expect(tersimpan.description, laporan.description);
    });

    test('retry mengirim clientReportId yang sama sehingga tidak menduplikasi',
        () async {
      var panggilan = 0;
      final repo = repositoriDengan((_) async {
        panggilan++;
        if (panggilan == 1) {
          return http.Response('{"error":"putus"}', 500);
        }
        return http.Response(
          jsonEncode(<String, Object?>{
            'serverId': 'SRV-000777',
            'duplicate': true,
          }),
          200,
        );
      });

      final laporan = laporanContoh();
      await repo.simpanDraft(laporan);
      await repo.kirim(laporan.localId);
      await repo.kirim(laporan.localId);

      expect(badanTerkirim.length, 2);
      expect(badanTerkirim[0]['clientReportId'], laporan.localId);
      expect(badanTerkirim[1]['clientReportId'], laporan.localId);

      final tersimpan = await repo.cari(laporan.localId);
      expect(tersimpan!.status, StatusSinkronisasi.success);
      expect(tersimpan.serverId, 'SRV-000777');
    });

    test('status SENDING yang tertinggal dipulihkan menjadi FAILED', () async {
      final repo = repositoriDengan((_) async => http.Response('{}', 201));
      final laporan = laporanContoh();
      await repo.simpanDraft(laporan);
      await lokal.ubahStatus(laporan.localId, StatusSinkronisasi.sending);

      final jumlah = await repo.pulihkanStatusTertinggal();

      expect(jumlah, 1);
      final tersimpan = await repo.cari(laporan.localId);
      expect(tersimpan!.status, StatusSinkronisasi.failed);
    });

    test('antrean hanya berisi PENDING dan FAILED', () async {
      final repo = repositoriDengan((_) async => http.Response('{}', 201));
      final a = laporanContoh();
      final b = laporanContoh();
      final c = laporanContoh();

      await repo.simpanDraft(a);
      await repo.simpanDraft(b);
      await repo.simpanDraft(c);
      await repo.antrekan(b.localId);
      await lokal.ubahStatus(a.localId, StatusSinkronisasi.success);
      await lokal.ubahStatus(c.localId, StatusSinkronisasi.failed);

      final antrean = await lokal.antrean();
      final id = antrean.map((l) => l.localId).toSet();

      expect(id.contains(b.localId), isTrue);
      expect(id.contains(c.localId), isTrue);
      expect(id.contains(a.localId), isFalse);
    });
  });
}

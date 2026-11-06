import 'package:flutter_test/flutter_test.dart';
import 'package:studylog_flutter/models/catatan.dart';

void main() {
  final tanggalUji = DateTime.utc(2026, 10, 29, 14, 30);

  group('Catatan.toMap', () {
    test('memakai nama kolom yang sama dengan skema SQLite', () {
      final catatan = Catatan(
        id: 1,
        mataKuliah: 'Pemrograman Aplikasi Bergerak',
        judul: 'Praktikum 3',
        isi: 'Belajar sqflite',
        tanggal: tanggalUji,
      );

      final peta = catatan.toMap();

      expect(peta.keys.toSet(), {
        'id',
        'mata_kuliah',
        'judul',
        'isi',
        'tanggal',
      });
      expect(peta['id'], 1);
      expect(peta['mata_kuliah'], 'Pemrograman Aplikasi Bergerak');
      expect(peta['judul'], 'Praktikum 3');
      expect(peta['isi'], 'Belajar sqflite');
    });

    test('menyimpan tanggal sebagai TEXT ISO 8601', () {
      final catatan = Catatan(
        mataKuliah: 'MK',
        judul: 'Judul',
        isi: 'Isi',
        tanggal: tanggalUji,
      );

      final peta = catatan.toMap();

      expect(peta['tanggal'], isA<String>());
      expect(peta['tanggal'], '2026-10-29T14:30:00.000Z');
      expect(DateTime.parse(peta['tanggal']! as String), tanggalUji);
    });

    test('id bernilai null untuk catatan yang belum tersimpan', () {
      final catatan = Catatan(
        mataKuliah: 'MK',
        judul: 'Judul',
        isi: 'Isi',
        tanggal: tanggalUji,
      );

      expect(catatan.toMap()['id'], isNull);
    });
  });

  group('Catatan.fromMap', () {
    test('membangun objek dari baris SQLite', () {
      final catatan = Catatan.fromMap({
        'id': 7,
        'mata_kuliah': 'Basis Data',
        'judul': 'Normalisasi',
        'isi': '1NF sampai 3NF',
        'tanggal': '2026-10-29T14:30:00.000Z',
      });

      expect(catatan.id, 7);
      expect(catatan.mataKuliah, 'Basis Data');
      expect(catatan.judul, 'Normalisasi');
      expect(catatan.isi, '1NF sampai 3NF');
      expect(catatan.tanggal, tanggalUji);
    });

    test('menerima id null', () {
      final catatan = Catatan.fromMap({
        'id': null,
        'mata_kuliah': 'MK',
        'judul': 'Judul',
        'isi': 'Isi',
        'tanggal': '2026-10-29T14:30:00.000Z',
      });

      expect(catatan.id, isNull);
    });
  });

  group('bolak-balik toMap dan fromMap', () {
    test('objek kembali utuh setelah dua kali konversi', () {
      final asli = Catatan(
        id: 3,
        mataKuliah: 'Sistem Operasi',
        judul: 'Penjadwalan CPU',
        isi: 'Round robin dan prioritas',
        tanggal: tanggalUji,
      );

      final hasil = Catatan.fromMap(asli.toMap());

      expect(hasil.id, asli.id);
      expect(hasil.mataKuliah, asli.mataKuliah);
      expect(hasil.judul, asli.judul);
      expect(hasil.isi, asli.isi);
      expect(hasil.tanggal, asli.tanggal);
    });
  });

  group('Catatan.copyWith', () {
    test('hanya mengganti field yang diberikan', () {
      final asli = Catatan(
        id: 5,
        mataKuliah: 'Jaringan',
        judul: 'Subnetting',
        isi: 'CIDR',
        tanggal: tanggalUji,
      );

      final hasil = asli.copyWith(judul: 'Subnetting dan VLSM');

      expect(hasil.id, 5);
      expect(hasil.judul, 'Subnetting dan VLSM');
      expect(hasil.mataKuliah, 'Jaringan');
      expect(hasil.tanggal, tanggalUji);
    });
  });
}
# StudyLog

Aplikasi Android untuk mencatat materi perkuliahan tanpa bergantung pada internet. Catatan disimpan di perangkat menggunakan SQLite, sehingga tetap ada setelah aplikasi ditutup dan dibuka kembali.

Proyek ini adalah tugas kelompok mata kuliah **Pemrograman Aplikasi Bergerak** (Program Studi Informatika, Universitas Mulia, kelas IFB5A), dikerjakan melalui **Workbook Praktikum 01 — Flutter Android**.

## Fitur

- Beranda dengan tombol menuju daftar catatan.
- Daftar catatan diurutkan dari yang terbaru, lengkap dengan tampilan kosong, memuat data, dan pesan galat dengan tombol Coba lagi.
- Tambah catatan (mata kuliah, judul, isi) dengan validasi: semua kolom wajib diisi.
- Detail catatan beserta tanggal dibuat.
- Ubah catatan.
- Hapus catatan dengan dialog konfirmasi.
- Penyimpanan lokal SQLite; berjalan sepenuhnya offline.

## Teknologi

- Flutter dan Dart (Material 3)
- `provider` untuk pengelolaan state (`ChangeNotifier`)
- `sqflite` dan `path` untuk database SQLite lokal

Arsitektur mengikuti alur berikut:

```
UI (screens) → ViewModel (ChangeNotifier) → Repository → DatabaseHelper (sqflite) → SQLite
```

## Prasyarat

- Flutter SDK versi stabil (diuji dengan Flutter 3.47.8, channel stable)
- Android SDK, serta emulator Android atau HP Android dengan USB debugging aktif
- Git

Periksa lingkungan dengan `flutter doctor`.

## Instalasi dan Menjalankan

```bash
git clone https://github.com/nifnip22/studylog-flutter.git
cd studylog-flutter
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d <ID_PERANGKAT_ANDROID>
```

Gunakan ID perangkat Android dari hasil `flutter devices`.

> **Penting:** jalankan aplikasi pada emulator atau HP Android. Jangan memilih target Chrome, Edge, atau Windows, karena paket `sqflite` pada proyek ini ditujukan untuk Android.

## Struktur Proyek

```
lib/
  main.dart
  models/catatan.dart
  data/database_helper.dart
  data/catatan_repository.dart
  viewmodels/catatan_view_model.dart
  screens/beranda_page.dart
  screens/daftar_catatan_page.dart
  screens/detail_catatan_page.dart
  screens/form_catatan_page.dart
test/catatan_model_test.dart
```

| Lapisan | File | Tanggung jawab |
|---|---|---|
| Model | `models/catatan.dart` | Objek `Catatan` dan konversi `toMap()` / `fromMap()` |
| Data | `data/database_helper.dart` | Membuka database `studylog.db` dan membuat tabel pada `onCreate` |
| Data | `data/catatan_repository.dart` | Operasi `semua()`, `tambah()`, `ubah()`, `hapus()` |
| ViewModel | `viewmodels/catatan_view_model.dart` | Menyimpan daftar, status memuat, dan galat; memuat ulang setelah setiap perubahan |
| UI | `screens/*.dart` | Beranda, daftar, detail dan hapus, form tambah/ubah |

## Skema Database

Tabel `catatan`:

| Kolom | Tipe | Aturan |
|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT |
| `mata_kuliah` | TEXT | NOT NULL |
| `judul` | TEXT | NOT NULL |
| `isi` | TEXT | NOT NULL |
| `tanggal` | TEXT | NOT NULL, format ISO 8601 |

Skema dibuat satu kali saat database pertama dibuat. Perubahan struktur tabel setelah aplikasi terpasang memerlukan strategi migrasi (versi database).

## Pengujian

- **Otomatis:** `flutter test` menjalankan `test/catatan_model_test.dart`, yang memeriksa konversi model ke Map dan sebaliknya.
- **Manual:** skenario CRUD T1–T7 (tambah, baca, ubah, hapus batal, hapus setuju, data bertahan setelah restart, validasi) beserta bukti screenshot didokumentasikan pada Workbook Praktikum 01.

Perangkat uji: Xiaomi Poco X6 Pro 5G (2311DRK48G), Android 16 (API 36).

## Pengembangan Bertahap

Proyek dikembangkan melalui tiga checkpoint pada workbook:

1. **M1** — form interaktif: `StatefulWidget`, `Form`, validator, `setState`.
2. **M2** — navigasi multi-layar dan state lintas layar dengan `Navigator` dan `Provider` (data di memori).
3. **M3** — SQLite, repository, ViewModel, dan CRUD dengan data permanen.

Kode pada branch `main` merupakan checkpoint **M3**.

## Anggota dan Kontribusi

| Nama | NIM | Kontribusi |
|---|---|---|
| Hanif Ahmad | 2411098 | Koordinator: pembuatan repo dan proyek, persiapan alat (Bab 2), dokumen gabungan, README, penyusunan dan pengumpulan akhir |
| Andi Ahmad Harun Arrasyid | 2411011 | M1 (form interaktif), pengujian dan dokumentasi Bab 3 |
| Jud Son Phangestu | 2411090 | M2 (navigasi dan state), pengujian dan dokumentasi Bab 4 |
| Muhammad Rengga Wicaksono | 2411044 | M3 sisi data (model, database helper, repository), `flutter analyze` dan `flutter test`, logbook debugging |
| Syanov Nur Rahmat | 2411056 | M3 sisi UI dan pengujian CRUD T1–T7, video demo |

## Sumber Kode

Kode checkpoint M1–M3 berasal dari paket pembelajaran StudyLog yang disediakan dosen pengampu. Kelompok menjalankan, menguji pada perangkat Android, dan mendokumentasikannya.
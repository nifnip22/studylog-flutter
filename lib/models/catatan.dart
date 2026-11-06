/// Model data untuk satu catatan perkuliahan.
///
/// Satu objek [Catatan] mewakili satu baris pada tabel `catatan` di SQLite.
/// Kelas ini sengaja tidak bergantung pada Flutter maupun sqflite supaya
/// mudah diuji lewat `flutter test`.
class Catatan {
  /// Nilai `null` berarti baris belum tersimpan; SQLite yang akan
  /// mengisinya lewat AUTOINCREMENT.
  final int? id;
  final String mataKuliah;
  final String judul;
  final String isi;

  /// Disimpan sebagai TEXT berformat ISO 8601, bukan tipe DATETIME,
  /// karena SQLite tidak punya tipe tanggal bawaan.
  final DateTime tanggal;

  const Catatan({
    this.id,
    required this.mataKuliah,
    required this.judul,
    required this.isi,
    required this.tanggal,
  });

  /// Mengubah objek menjadi peta kolom. Kunci peta harus sama dengan
  /// nama kolom pada `CREATE TABLE` di [DatabaseHelper].
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'mata_kuliah': mataKuliah,
      'judul': judul,
      'isi': isi,
      'tanggal': tanggal.toIso8601String(),
    };
  }

  /// Kebalikan dari [toMap]: membangun objek dari baris hasil query.
  factory Catatan.fromMap(Map<String, Object?> map) {
    return Catatan(
      id: map['id'] as int?,
      mataKuliah: map['mata_kuliah'] as String,
      judul: map['judul'] as String,
      isi: map['isi'] as String,
      tanggal: DateTime.parse(map['tanggal'] as String),
    );
  }

  /// Dipakai saat mengubah catatan: seluruh isi diganti, `id` dan
  /// `tanggal` asli dipertahankan.
  Catatan copyWith({
    int? id,
    String? mataKuliah,
    String? judul,
    String? isi,
    DateTime? tanggal,
  }) {
    return Catatan(
      id: id ?? this.id,
      mataKuliah: mataKuliah ?? this.mataKuliah,
      judul: judul ?? this.judul,
      isi: isi ?? this.isi,
      tanggal: tanggal ?? this.tanggal,
    );
  }

  @override
  String toString() =>
      'Catatan(id: $id, mataKuliah: $mataKuliah, judul: $judul, '
      'tanggal: ${tanggal.toIso8601String()})';
}
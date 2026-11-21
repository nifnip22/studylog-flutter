import 'package:uuid/uuid.dart';

/// Status sinkronisasi laporan. Nilai ini yang disimpan apa adanya di SQLite.
enum StatusSinkronisasi { draft, pending, sending, success, failed }

extension StatusSinkronisasiLabel on StatusSinkronisasi {
  String get label => switch (this) {
        StatusSinkronisasi.draft => 'DRAFT',
        StatusSinkronisasi.pending => 'PENDING',
        StatusSinkronisasi.sending => 'SENDING',
        StatusSinkronisasi.success => 'SUCCESS',
        StatusSinkronisasi.failed => 'FAILED',
      };

  /// Status yang masih boleh masuk antrean kirim.
  bool get perluDikirim =>
      this == StatusSinkronisasi.pending || this == StatusSinkronisasi.failed;
}

StatusSinkronisasi statusDariLabel(String label) {
  final dicari = label.toUpperCase();
  for (final status in StatusSinkronisasi.values) {
    if (status.label == dicari) return status;
  }
  return StatusSinkronisasi.draft;
}

/// Satu laporan kerusakan fasilitas kampus.
///
/// localId dibuat sekali di perangkat dan tidak pernah berubah, termasuk saat
/// pengiriman ulang. Nilai itulah yang dipakai server sebagai clientReportId
/// untuk mencegah laporan ganda.
class Laporan {
  const Laporan({
    required this.localId,
    required this.title,
    required this.category,
    required this.description,
    required this.priority,
    required this.createdAt,
    this.photoPath,
    this.latitude,
    this.longitude,
    this.status = StatusSinkronisasi.draft,
    this.serverId,
    this.lastError,
  });

  static const Uuid _uuid = Uuid();

  final String localId;
  final String title;
  final String category;
  final String description;
  final String priority;
  final DateTime createdAt;
  final String? photoPath;
  final double? latitude;
  final double? longitude;
  final StatusSinkronisasi status;
  final String? serverId;
  final String? lastError;

  factory Laporan.baru({
    required String title,
    required String category,
    required String description,
    required String priority,
  }) =>
      Laporan(
        localId: _uuid.v4(),
        title: title,
        category: category,
        description: description,
        priority: priority,
        createdAt: DateTime.now().toUtc(),
      );

  bool get punyaLokasi => latitude != null && longitude != null;

  bool get punyaFoto => photoPath != null && photoPath!.isNotEmpty;

  Map<String, Object?> toMap() => {
        'local_id': localId,
        'title': title,
        'category': category,
        'description': description,
        'priority': priority,
        'created_at': createdAt.toUtc().toIso8601String(),
        'photo_path': photoPath,
        'latitude': latitude,
        'longitude': longitude,
        'status': status.label,
        'server_id': serverId,
        'last_error': lastError,
      };

  factory Laporan.fromMap(Map<String, Object?> map) => Laporan(
        localId: map['local_id']! as String,
        title: map['title']! as String,
        category: map['category']! as String,
        description: map['description']! as String,
        priority: (map['priority'] as String?) ?? 'sedang',
        createdAt: DateTime.parse(map['created_at']! as String).toUtc(),
        photoPath: map['photo_path'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        status: statusDariLabel((map['status'] as String?) ?? 'DRAFT'),
        serverId: map['server_id'] as String?,
        lastError: map['last_error'] as String?,
      );

  /// Isi permintaan POST /reports.
  Map<String, Object?> toJsonBody({String? photoBase64}) => {
        'clientReportId': localId,
        'title': title,
        'category': category,
        'description': description,
        'priority': priority,
        'createdAt': createdAt.toUtc().toIso8601String(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (photoBase64 != null) 'photoBase64': photoBase64,
      };

  Laporan copyWith({
    StatusSinkronisasi? status,
    String? photoPath,
    double? latitude,
    double? longitude,
    String? serverId,
    String? lastError,
    bool hapusError = false,
  }) =>
      Laporan(
        localId: localId,
        title: title,
        category: category,
        description: description,
        priority: priority,
        createdAt: createdAt,
        photoPath: photoPath ?? this.photoPath,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        status: status ?? this.status,
        serverId: serverId ?? this.serverId,
        lastError: hapusError ? null : (lastError ?? this.lastError),
      );
}

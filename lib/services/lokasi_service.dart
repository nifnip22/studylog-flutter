import 'package:geolocator/geolocator.dart';

/// Hasil satu percobaan pengambilan lokasi.
///
/// Penolakan izin bukan kegagalan aplikasi: laporan tetap bisa disimpan
/// tanpa lokasi, jadi hasilnya dikembalikan sebagai pesan, bukan dilempar
/// sebagai galat.
class HasilLokasi {
  const HasilLokasi({
    this.latitude,
    this.longitude,
    required this.pesan,
    this.ditolak = false,
  });

  final double? latitude;
  final double? longitude;
  final String pesan;
  final bool ditolak;

  bool get dapat => latitude != null && longitude != null;
}

class LokasiService {
  Future<HasilLokasi> ambilLokasi() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const HasilLokasi(
          pesan: 'Layanan lokasi perangkat mati. Laporan tetap bisa disimpan '
              'tanpa lokasi.',
        );
      }

      LocationPermission izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }
      if (izin == LocationPermission.denied ||
          izin == LocationPermission.deniedForever) {
        return const HasilLokasi(
          pesan: 'Izin lokasi ditolak. Laporan tetap bisa disimpan tanpa '
              'lokasi.',
          ditolak: true,
        );
      }

      final posisi = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return HasilLokasi(
        latitude: posisi.latitude,
        longitude: posisi.longitude,
        pesan: 'Lokasi ditambahkan.',
      );
    } catch (galat) {
      return HasilLokasi(
        pesan: 'Lokasi tidak terbaca: $galat. Laporan tetap bisa disimpan.',
      );
    }
  }
}

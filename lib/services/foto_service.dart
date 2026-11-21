import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Pengelola foto laporan.
///
/// Berkas hasil jepretan kamera disalin lebih dahulu ke direktori dokumen
/// aplikasi. Jalur berkas sementara milik image_picker tidak dipakai karena
/// isinya bisa dibersihkan sistem kapan saja, sehingga foto akan hilang
/// setelah aplikasi ditutup.
class FotoService {
  FotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> ambilFoto(String localId) async {
    final XFile? jepretan = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (jepretan == null) return null;

    final dokumen = await getApplicationDocumentsDirectory();
    final tujuan = p.join(dokumen.path, 'laporan_$localId.jpg');
    await File(jepretan.path).copy(tujuan);
    return tujuan;
  }

  Future<void> hapusFoto(String? jalur) async {
    if (jalur == null) return;
    final berkas = File(jalur);
    if (berkas.existsSync()) await berkas.delete();
  }

  Future<String?> keBase64(String? jalur) async {
    if (jalur == null || jalur.isEmpty) return null;
    final berkas = File(jalur);
    if (!berkas.existsSync()) return null;
    return base64Encode(await berkas.readAsBytes());
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/laporan.dart';
import '../../viewmodels/laporan_view_model.dart';

const List<String> daftarKategori = <String>[
  'Listrik',
  'Pendingin Ruangan',
  'Perabot',
  'Proyektor',
  'Jaringan',
  'Kebersihan',
  'Lain-lain',
];

class FormLaporanPage extends StatefulWidget {
  const FormLaporanPage({super.key});

  @override
  State<FormLaporanPage> createState() => _FormLaporanPageState();
}

class _FormLaporanPageState extends State<FormLaporanPage> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _judul = TextEditingController();
  final TextEditingController _deskripsi = TextEditingController();

  String _kategori = daftarKategori.first;
  String _prioritas = 'sedang';
  String? _photoPath;
  double? _latitude;
  double? _longitude;
  String? _catatanKonteks;
  bool _sibuk = false;

  @override
  void dispose() {
    _judul.dispose();
    _deskripsi.dispose();
    super.dispose();
  }

  Future<void> _ambilFoto() async {
    final viewModel = context.read<LaporanViewModel>();
    final String idSementara = DateTime.now().microsecondsSinceEpoch.toString();
    final String? jalur = await viewModel.ambilFoto(idSementara);
    if (!mounted) return;
    if (jalur == null) {
      setState(() => _catatanKonteks = 'Pengambilan foto dibatalkan.');
      return;
    }
    setState(() {
      _photoPath = jalur;
      _catatanKonteks = 'Foto tersimpan di: $jalur';
    });
  }

  Future<void> _ambilLokasi() async {
    final viewModel = context.read<LaporanViewModel>();
    final hasil = await viewModel.ambilLokasi();
    if (!mounted) return;
    setState(() {
      _latitude = hasil.latitude;
      _longitude = hasil.longitude;
      _catatanKonteks = hasil.pesan;
    });
  }

  Future<void> _simpan({required bool langsungKirim}) async {
    if (!(_form.currentState?.validate() ?? false)) return;

    setState(() => _sibuk = true);
    final viewModel = context.read<LaporanViewModel>();
    final navigator = Navigator.of(context);

    final laporan = Laporan.baru(
      title: _judul.text.trim(),
      category: _kategori,
      description: _deskripsi.text.trim(),
      priority: _prioritas,
    ).copyWith(
      photoPath: _photoPath,
      latitude: _latitude,
      longitude: _longitude,
    );

    await viewModel.simpan(laporan, langsungKirim: langsungKirim);
    if (!mounted) return;
    setState(() => _sibuk = false);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Baru')),
      body: AbsorbPointer(
        absorbing: _sibuk,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Form(
              key: _form,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: _judul,
                    decoration: const InputDecoration(
                      labelText: 'Judul laporan',
                      helperText: 'Minimal 6 karakter, misalnya AC ruang IFB5A mati',
                      border: OutlineInputBorder(),
                    ),
                    validator: (nilai) {
                      final teks = nilai?.trim() ?? '';
                      if (teks.isEmpty) return 'Judul wajib diisi';
                      if (teks.length < 6) return 'Judul terlalu pendek';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _kategori,
                    decoration: const InputDecoration(
                      labelText: 'Kategori fasilitas',
                      border: OutlineInputBorder(),
                    ),
                    items: daftarKategori
                        .map((e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (nilai) {
                      if (nilai != null) setState(() => _kategori = nilai);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _deskripsi,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi kerusakan',
                      helperText: 'Minimal 20 karakter supaya petugas paham',
                      border: OutlineInputBorder(),
                    ),
                    validator: (nilai) {
                      final teks = nilai?.trim() ?? '';
                      if (teks.isEmpty) return 'Deskripsi wajib diisi';
                      if (teks.length < 20) return 'Deskripsi terlalu pendek';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Prioritas', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'rendah', label: Text('Rendah')),
                ButtonSegment<String>(value: 'sedang', label: Text('Sedang')),
                ButtonSegment<String>(value: 'tinggi', label: Text('Tinggi')),
              ],
              selected: <String>{_prioritas},
              onSelectionChanged: (pilihan) =>
                  setState(() => _prioritas = pilihan.first),
            ),
            const SizedBox(height: 20),
            const Text('Konteks (opsional)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _ambilFoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(_photoPath == null ? 'Ambil Foto' : 'Ganti Foto'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _ambilLokasi,
                    icon: const Icon(Icons.my_location_outlined),
                    label: Text(_latitude == null ? 'Ambil Lokasi' : 'Perbarui'),
                  ),
                ),
              ],
            ),
            if (_photoPath != null) ...<Widget>[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(File(_photoPath!), height: 180, fit: BoxFit.cover),
              ),
            ],
            if (_latitude != null && _longitude != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                'Koordinat: ${_latitude!.toStringAsFixed(6)}, '
                '${_longitude!.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 12.5),
              ),
            ],
            if (_catatanKonteks != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                _catatanKonteks!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _sibuk ? null : () => _simpan(langsungKirim: false),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Simpan Offline'),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: _sibuk ? null : () => _simpan(langsungKirim: true),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Antrekan & Kirim'),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

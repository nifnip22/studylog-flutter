import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catatan.dart';
import '../viewmodels/catatan_view_model.dart';

/// Form tambah sekaligus ubah. Bila [catatan] bernilai null, form
/// berjalan dalam mode tambah.
class FormPage extends StatefulWidget {
  const FormPage({super.key, this.catatan});

  final Catatan? catatan;

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _mk;
  late final TextEditingController _judul;
  late final TextEditingController _isi;
  bool _menyimpan = false;

  bool get _modeUbah => widget.catatan != null;

  @override
  void initState() {
    super.initState();
    final awal = widget.catatan;
    _mk = TextEditingController(text: awal?.mataKuliah ?? '');
    _judul = TextEditingController(text: awal?.judul ?? '');
    _isi = TextEditingController(text: awal?.isi ?? '');
  }

  @override
  void dispose() {
    _mk.dispose();
    _judul.dispose();
    _isi.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _menyimpan = true);

    final vm = context.read<CatatanViewModel>();
    final pesan = ScaffoldMessenger.of(context);
    final tanggal = widget.catatan?.tanggal ?? DateTime.now();

    final catatan = Catatan(
      id: widget.catatan?.id,
      mataKuliah: _mk.text.trim(),
      judul: _judul.text.trim(),
      isi: _isi.text.trim(),
      tanggal: tanggal,
    );

    final berhasil = _modeUbah ? await vm.ubah(catatan) : await vm.tambah(catatan);

    if (!mounted) return;
    setState(() => _menyimpan = false);

    if (berhasil) {
      Navigator.pop(context, true);
    } else {
      pesan.showSnackBar(
        SnackBar(content: Text(vm.error ?? 'Gagal menyimpan catatan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_modeUbah ? 'Ubah Catatan' : 'Tambah Catatan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field(
              controller: _mk,
              label: 'Mata kuliah',
              ikon: Icons.school_outlined,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _judul,
              label: 'Judul',
              ikon: Icons.title_rounded,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _isi,
              label: 'Isi',
              ikon: Icons.notes_rounded,
              baris: 5,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _menyimpan ? null : _simpan,
              icon: _menyimpan
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_menyimpan ? 'Menyimpan...' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData ikon,
    int baris = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: baris,
      textInputAction: baris > 1 ? TextInputAction.newline : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(ikon),
        border: const OutlineInputBorder(),
      ),
      validator: (nilai) {
        if (nilai == null || nilai.trim().isEmpty) {
          return '$label wajib diisi';
        }
        if (label == 'Mata kuliah' && nilai.trim().length < 3) {
          return 'Mata kuliah minimal 3 karakter';
        }
        if (label == 'Judul' && nilai.trim().length < 3) {
          return 'Judul minimal 3 karakter';
        }
        return null;
      },
    );
  }
}
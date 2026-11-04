import 'package:flutter/material.dart';

void main() => runApp(const StudyLogApp());

class StudyLogApp extends StatelessWidget {
  const StudyLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyLog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const FormCatatanPage(),
    );
  }
}

class FormCatatanPage extends StatefulWidget {
  const FormCatatanPage({super.key});

  @override
  State<FormCatatanPage> createState() => _FormCatatanPageState();
}

class _FormCatatanPageState extends State<FormCatatanPage> {
  final _formKey = GlobalKey<FormState>();
  final _mataKuliahCtrl = TextEditingController();
  final _topikCtrl = TextEditingController();
  final _judulCtrl = TextEditingController();
  final _isiCtrl = TextEditingController();

  // Data hasil simpan (hanya di memori / state, bukan database).
  String? _mataKuliah;
  String? _topik;
  String? _judul;
  String? _isi;

  // Latihan mandiri: tombol berubah saat berhasil menyimpan.
  bool _berhasil = false;

  @override
  void dispose() {
    _mataKuliahCtrl.dispose();
    _topikCtrl.dispose();
    _judulCtrl.dispose();
    _isiCtrl.dispose();
    super.dispose();
  }

  String? _wajibDiisi(String? value, String label) {
    // trim() membuat input berisi spasi saja dianggap kosong (M1-T2).
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi';
    }
    return null;
  }

  String? _validasiTopik(String? value) {
    final wajib = _wajibDiisi(value, 'Topik');
    if (wajib != null) return wajib;
    if (value!.trim().length < 3) return 'Topik minimal 3 karakter';
    return null;
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _berhasil = false);
      return;
    }
    setState(() {
      _mataKuliah = _mataKuliahCtrl.text.trim();
      _topik = _topikCtrl.text.trim();
      _judul = _judulCtrl.text.trim();
      _isi = _isiCtrl.text.trim();
      _berhasil = true;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Catatan berhasil disimpan')),
      );
  }

  void _tandaiBelumDisimpan(String _) {
    if (_berhasil) setState(() => _berhasil = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StudyLog — Form Catatan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _mataKuliahCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mata kuliah',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _tandaiBelumDisimpan,
                    validator: (v) => _wajibDiisi(v, 'Mata kuliah'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _topikCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Topik',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _tandaiBelumDisimpan,
                    validator: _validasiTopik,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _judulCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Judul',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _tandaiBelumDisimpan,
                    validator: (v) => _wajibDiisi(v, 'Judul'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _isiCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Isi catatan',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _tandaiBelumDisimpan,
                    validator: (v) => _wajibDiisi(v, 'Isi catatan'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _simpan,
              style: FilledButton.styleFrom(
                backgroundColor: _berhasil ? Colors.green : null,
              ),
              icon: Icon(_berhasil ? Icons.check_circle : Icons.save),
              label: Text(_berhasil ? 'Tersimpan' : 'Simpan'),
            ),
            const SizedBox(height: 24),
            if (_judul != null)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _mataKuliah!,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _judul!,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Topik: $_topik',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Divider(height: 24),
                      Text(_isi!),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

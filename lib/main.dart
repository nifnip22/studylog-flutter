import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (_) => CatatanStore(),
    child: const StudyLogApp(),
  ));
}

class CatatanMini {
  final String mataKuliah;
  final String judul;
  final String isi;
  const CatatanMini(this.mataKuliah, this.judul, this.isi);
}

class CatatanStore extends ChangeNotifier {
  final List<CatatanMini> _data = [];
  List<CatatanMini> get data => List.unmodifiable(_data);

  void tambah(CatatanMini catatan) {
    _data.add(catatan);
    notifyListeners();
  }
}

class StudyLogApp extends StatelessWidget {
  const StudyLogApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'StudyLog | Praktikum 2',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const BerandaPage(),
      );
}

class BerandaPage extends StatelessWidget {
  const BerandaPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('StudyLog')),
        body: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_rounded, size: 72),
            const SizedBox(height: 12),
            const Text('Catatan perkuliahan', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const DaftarPage())),
              child: const Text('Buka Daftar Catatan')),
          ],
        )),
      );
}

class DaftarPage extends StatelessWidget {
  const DaftarPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Daftar Catatan')),
        body: Consumer<CatatanStore>(builder: (context, store, _) {
          if (store.data.isEmpty) {
            return const Center(child: Text('Belum ada catatan. Tambahkan melalui tombol +.'));
          }
          return ListView.builder(
            itemCount: store.data.length,
            itemBuilder: (context, index) {
              final item = store.data[index];
              return ListTile(
                title: Text(item.judul),
                subtitle: Text(item.mataKuliah),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => DetailPage(catatan: item))),
              );
            },
          );
        }),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const FormPage())),
          child: const Icon(Icons.add),
        ),
      );
}

class DetailPage extends StatelessWidget {
  final CatatanMini catatan;
  const DetailPage({super.key, required this.catatan});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Detail Catatan')),
        body: Padding(padding: const EdgeInsets.all(20), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(catatan.mataKuliah, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            Text(catatan.judul, style: Theme.of(context).textTheme.headlineMedium),
            const Divider(height: 32),
            Text(catatan.isi),
          ],
        )),
      );
}

class FormPage extends StatefulWidget {
  const FormPage({super.key});
  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _form = GlobalKey<FormState>();
  final _mk = TextEditingController();
  final _judul = TextEditingController();
  final _isi = TextEditingController();

  @override
  void dispose() {
    _mk.dispose(); _judul.dispose(); _isi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tambah Catatan')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Form(key: _form, child: Column(children: [
            _field(_mk, 'Mata kuliah'),
            const SizedBox(height: 12),
            _field(_judul, 'Judul'),
            const SizedBox(height: 12),
            _field(_isi, 'Isi', baris: 4),
          ])),
          const SizedBox(height: 20),
          FilledButton(onPressed: () {
            if (!_form.currentState!.validate()) return;
            context.read<CatatanStore>().tambah(CatatanMini(
              _mk.text.trim(), _judul.text.trim(), _isi.text.trim()));
            Navigator.pop(context);
          }, child: const Text('Simpan Sementara')),
        ]),
      );

  Widget _field(TextEditingController controller, String label, {int baris = 1}) {
    return TextFormField(
      controller: controller, maxLines: baris,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (nilai) => (nilai == null || nilai.trim().isEmpty)
          ? '$label wajib diisi' : null,
    );
  }
}

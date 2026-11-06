import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catatan.dart';
import '../viewmodels/catatan_view_model.dart';
import 'detail_page.dart';
import 'form_page.dart';

/// Daftar seluruh catatan. Isi layar berasal dari [CatatanViewModel],
/// bukan dari state lokal, sehingga perubahan di layar lain ikut tampil.
class DaftarPage extends StatelessWidget {
  const DaftarPage({super.key});

  Future<void> _bukaForm(BuildContext context, {Catatan? catatan}) async {
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FormPage(catatan: catatan)),
    );
    if (berhasil == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(catatan == null ? 'Catatan disimpan' : 'Catatan diperbarui'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Catatan'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () => context.read<CatatanViewModel>().muatUlang(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Consumer<CatatanViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && vm.daftar.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final pesanError = vm.error;
          if (pesanError != null && vm.daftar.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48),
                    const SizedBox(height: 12),
                    Text(pesanError, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: vm.muatUlang,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (vm.kosong) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada catatan.\nTekan tombol + untuk menambahkan.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: vm.muatUlang,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              itemCount: vm.daftar.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final catatan = vm.daftar[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        catatan.mataKuliah.isEmpty
                            ? '?'
                            : catatan.mataKuliah[0].toUpperCase(),
                      ),
                    ),
                    title: Text(
                      catatan.judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${catatan.mataKuliah} • ${_formatTanggal(catatan.tanggal)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailPage(catatan: catatan),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }

  static String _formatTanggal(DateTime tanggal) {
    final lokal = tanggal.toLocal();
    String dua(int angka) => angka.toString().padLeft(2, '0');
    return '${dua(lokal.day)}/${dua(lokal.month)}/${lokal.year} '
        '${dua(lokal.hour)}:${dua(lokal.minute)}';
  }
}
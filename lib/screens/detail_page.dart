import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catatan.dart';
import '../viewmodels/catatan_view_model.dart';
import 'form_page.dart';

/// Menampilkan isi satu catatan, dengan aksi ubah dan hapus.
class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.catatan});

  final Catatan catatan;

  Future<void> _ubah(BuildContext context) async {
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FormPage(catatan: catatan)),
    );
    if (berhasil == true && context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _hapus(BuildContext context) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text(
          'Catatan "${catatan.judul}" akan dihapus permanen dari database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (setuju != true || !context.mounted) return;

    final vm = context.read<CatatanViewModel>();
    final pesan = ScaffoldMessenger.of(context);
    final berhasil = await vm.hapus(catatan.id!);

    if (!context.mounted) return;
    if (berhasil) {
      Navigator.pop(context);
    } else {
      pesan.showSnackBar(
        SnackBar(content: Text(vm.error ?? 'Gagal menghapus catatan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan'),
        actions: [
          IconButton(
            tooltip: 'Ubah',
            onPressed: () => _ubah(context),
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: 'Hapus',
            onPressed: () => _hapus(context),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Chip(
            label: Text(catatan.mataKuliah),
            avatar: const Icon(Icons.school_rounded, size: 18),
          ),
          const SizedBox(height: 12),
          Text(catatan.judul, style: tema.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            _formatTanggal(catatan.tanggal),
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
          const Divider(height: 32),
          Text(catatan.isi, style: tema.textTheme.bodyLarge),
        ],
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
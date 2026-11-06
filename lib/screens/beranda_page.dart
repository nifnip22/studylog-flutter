import 'package:flutter/material.dart';

import 'daftar_page.dart';

/// Layar pembuka: penjelasan singkat dan tombol menuju daftar catatan.
class BerandaPage extends StatelessWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('StudyLog')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 80,
                color: tema.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Catatan Perkuliahan',
                style: tema.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tersimpan permanen di SQLite, tetap ada setelah aplikasi ditutup.',
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DaftarPage()),
                ),
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('Buka Daftar Catatan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
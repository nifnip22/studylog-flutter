import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/laporan.dart';
import '../../viewmodels/laporan_view_model.dart';
import 'lencana_status.dart';

class DetailLaporanPage extends StatelessWidget {
  const DetailLaporanPage({super.key, required this.localId});

  final String localId;

  @override
  Widget build(BuildContext context) {
    return Consumer<LaporanViewModel>(
      builder: (context, viewModel, _) {
        Laporan? ditemukan;
        for (final item in viewModel.daftar) {
          if (item.localId == localId) {
            ditemukan = item;
            break;
          }
        }

        if (ditemukan == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Laporan')),
            body: const Center(child: Text('Laporan tidak lagi tersimpan.')),
          );
        }
        final Laporan laporan = ditemukan;

        return Scaffold(
          appBar: AppBar(title: const Text('Detail Laporan')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Row(
                children: <Widget>[
                  LencanaStatus(status: laporan.status),
                  const SizedBox(width: 10),
                  Text(
                    laporan.priority.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                laporan.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(laporan.category,
                  style: Theme.of(context).textTheme.labelLarge),
              const Divider(height: 32),
              Text(laporan.description),
              const SizedBox(height: 22),
              _baris('Dibuat', laporan.createdAt.toLocal().toString()),
              _baris('Local ID', laporan.localId),
              _baris('Server ID', laporan.serverId ?? 'belum ada'),
              if (laporan.punyaLokasi)
                _baris(
                  'Koordinat',
                  '${laporan.latitude!.toStringAsFixed(6)}, '
                      '${laporan.longitude!.toStringAsFixed(6)}',
                )
              else
                _baris('Koordinat', 'tidak dilampirkan'),
              if (laporan.lastError != null) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    laporan.lastError!,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF991B1B)),
                  ),
                ),
              ],
              if (laporan.punyaFoto) ...<Widget>[
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(laporan.photoPath!),
                    height: 260,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      alignment: Alignment.center,
                      color: const Color(0xFFF1F5F9),
                      child: const Text('Foto tidak ditemukan di perangkat.'),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              if (laporan.status == StatusSinkronisasi.draft ||
                  laporan.status == StatusSinkronisasi.failed)
                FilledButton.icon(
                  onPressed: viewModel.memuat
                      ? null
                      : () => viewModel.kirimUlang(laporan.localId),
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Coba Kirim Lagi'),
                ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await viewModel.hapus(laporan.localId);
                  navigator.pop();
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus Laporan'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _baris(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(nilai, style: const TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/laporan.dart';
import '../../viewmodels/laporan_view_model.dart';
import 'detail_laporan_page.dart';
import 'form_laporan_page.dart';
import 'lencana_status.dart';

class LaporanFasilitasPage extends StatefulWidget {
  const LaporanFasilitasPage({super.key});

  @override
  State<LaporanFasilitasPage> createState() => _LaporanFasilitasPageState();
}

class _LaporanFasilitasPageState extends State<LaporanFasilitasPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LaporanViewModel>().muat();
    });
  }

  Future<void> _bukaForm() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const FormLaporanPage()),
    );
  }

  Future<void> _bukaDetail(Laporan laporan) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailLaporanPage(localId: laporan.localId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Fasilitas'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Kirim seluruh antrean',
            onPressed: () async {
              final viewModel = context.read<LaporanViewModel>();
              await viewModel.kirimSemuaAntrean();
            },
            icon: const Icon(Icons.cloud_upload_outlined),
          ),
        ],
      ),
      body: Consumer<LaporanViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.memuat && viewModel.daftar.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: <Widget>[
              _ringkasan(viewModel),
              const Divider(height: 1),
              Expanded(
                child: viewModel.daftar.isEmpty
                    ? _kosong()
                    : RefreshIndicator(
                        onRefresh: viewModel.muat,
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 88),
                          itemCount: viewModel.daftar.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final laporan = viewModel.daftar[index];
                            return _kartu(laporan);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _bukaForm,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Laporan Baru'),
      ),
    );
  }

  Widget _ringkasan(LaporanViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: <Widget>[
          const Icon(Icons.offline_bolt_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${viewModel.daftar.length} laporan - '
              '${viewModel.jumlahDraft} draft - '
              '${viewModel.jumlahGagal} gagal',
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kosong() {
    return ListView(
      children: const <Widget>[
        SizedBox(height: 120),
        Icon(Icons.report_gmailerrorred_outlined, size: 64),
        SizedBox(height: 12),
        Center(
          child: Text(
            'Belum ada laporan.\nTekan Laporan Baru untuk mulai.',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _kartu(Laporan laporan) {
    return ListTile(
      onTap: () => _bukaDetail(laporan),
      leading: CircleAvatar(
        backgroundColor:
            LencanaStatus.warna(laporan.status).withValues(alpha: 0.15),
        child: Icon(
          laporan.punyaFoto
              ? Icons.photo_camera_outlined
              : Icons.description_outlined,
          color: LencanaStatus.warna(laporan.status),
        ),
      ),
      title: Text(
        laporan.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              LencanaStatus(status: laporan.status),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  laporan.category,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (laporan.status == StatusSinkronisasi.failed &&
              laporan.lastError != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              laporan.lastError!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)),
            ),
          ],
        ],
      ),
      isThreeLine: laporan.status == StatusSinkronisasi.failed,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

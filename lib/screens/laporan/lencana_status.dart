import 'package:flutter/material.dart';

import '../../models/laporan.dart';

/// Lencana warna status sinkronisasi supaya pengguna bisa membedakan
/// laporan yang sudah aman dari laporan yang perlu perhatian dalam sekali
/// pandang, tanpa membuka detailnya.
class LencanaStatus extends StatelessWidget {
  const LencanaStatus({super.key, required this.status});

  final StatusSinkronisasi status;

  static Color warna(StatusSinkronisasi status) => switch (status) {
        StatusSinkronisasi.draft => const Color(0xFF64748B),
        StatusSinkronisasi.pending => const Color(0xFF0284C7),
        StatusSinkronisasi.sending => const Color(0xFFD97706),
        StatusSinkronisasi.success => const Color(0xFF16A34A),
        StatusSinkronisasi.failed => const Color(0xFFDC2626),
      };

  @override
  Widget build(BuildContext context) {
    final Color dasar = warna(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: dasar.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dasar, width: 1.2),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: dasar,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

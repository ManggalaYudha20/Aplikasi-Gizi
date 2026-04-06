// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\patient_home\presentation\widgets\patient_info_row.dart
//
// Reusable widget yang diekstrak dari _buildInfoRow() pada:
//   - patient_detail_page.dart
//   - patient_anak_detail_page.dart
//
// Gunakan widget ini di mana pun Anda perlu menampilkan pasangan
// label ↔ nilai secara horizontal dengan gaya yang konsisten.

import 'package:flutter/material.dart';

/// Menampilkan satu baris informasi dengan [label] di kiri dan [value]
/// di kanan (rata kanan).
///
/// Contoh penggunaan:
/// ```dart
/// PatientInfoRow('No. RM', patient.noRM),
/// PatientInfoRow('Berat Badan', '${patient.beratBadan} kg', isBold: true),
/// PatientInfoRow('Interpretasi', patient.interpretasi,
///     isBold: true, valueColor: Colors.red),
/// ```
class PatientInfoRow extends StatelessWidget {
  /// Teks label di sisi kiri.
  final String label;

  /// Nilai yang ditampilkan di sisi kanan.
  final String value;

  /// Apakah [value] ditampilkan dengan font bold. Default: `false`.
  final bool isBold;

  /// Warna teks [value]. Default: `Colors.black87`.
  final Color? valueColor;

  const PatientInfoRow(
    this.label,
    this.value, {
    super.key,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Label (kiri) ──────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 16),
          // ── Value (kanan) ─────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

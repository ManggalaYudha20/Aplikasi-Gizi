// lib/src/shared/utils/form_validator_utils.dart

import 'package:flutter/material.dart';

/// Sebuah kelas utilitas untuk membantu menangani validasi form.
class FormValidatorUtils {
  /// Memvalidasi form. Jika tidak valid, akan scroll ke field pertama yang error,
  /// memberikan fokus, dan menampilkan Snackbar.
  static bool validateAndScroll({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required List<FocusNode> focusNodes,
  }) {
    // 1. Jalankan validasi untuk menandai semua field yang error.
    if (formKey.currentState!.validate()) {
      return true; // Form valid.
    }

    // 2. Jika tidak valid, cari field pertama yang ditandai error.
    for (final node in focusNodes) {
      // Pastikan FocusNode terpasang pada sebuah widget.
      if (node.context != null) {
        // Cari FormFieldState terdekat dari widget yang memiliki fokus.
        // Ini adalah perbaikan dari kode sebelumnya.
        final formFieldState = node.context!.findAncestorStateOfType<FormFieldState>();

        // Periksa apakah field ini memiliki error.
        if (formFieldState != null && formFieldState.hasError) {
          
          // 3. Jika ditemukan, scroll ke field tersebut.
          Scrollable.ensureVisible(
            node.context!,
            duration: const Duration(milliseconds: 300),
            alignment: 0.1, // Beri sedikit padding di atas.
          ).then((_) {
            // 4. Setelah scroll, berikan fokus agar keyboard muncul.
            node.requestFocus();
          });

          // Hentikan proses setelah menemukan dan scroll ke error pertama.
          return false; 
        }
      }
    }

    // Fallback jika tidak ada field error yang terdeteksi (seharusnya tidak terjadi).
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Harap lengkapi semua data yang wajib diisi.'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }
}
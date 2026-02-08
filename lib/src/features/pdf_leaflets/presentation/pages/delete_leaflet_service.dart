// lib\src\features\pdf_leaflets\presentation\pages\delete_leaflet_service.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/leaflet_list_model.dart';

class DeleteLeafletService {
  /// Menampilkan dialog konfirmasi dan menangani proses penghapusan
  static Future<void> handleLeafletDelete({
    required BuildContext context,
    required Leaflet leaflet,
  }) async {
    // Tampilkan Dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin untuk menghapus leaflet "${leaflet.title}"?'),
          actions: [
            TextButton(
              key: const Key('dialog_cancel_button'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              key: const Key('dialog_confirm_delete_button'),
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      await _performDelete(context, leaflet);
    }
  }

  static Future<void> _performDelete(BuildContext context, Leaflet leaflet) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // Loading Indicator
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Menghapus Leaflet...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Firestore Delete
      await FirebaseFirestore.instance
          .collection('leaflets')
          .doc(leaflet.id)
          .delete();
      
      // Success Feedback
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Berhasil Menghapus Leaflet!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate Back
      navigator.pop(); 
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Gagal Menghapus Leaflet: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
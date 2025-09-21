import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/leaflet_list_model.dart';

class DeleteLeafletService {
  /// Shows a confirmation dialog for deleting a leaflet
  static Future<void> showDeleteConfirmationDialog({
    required BuildContext context,
    required Leaflet leaflet,
    required VoidCallback onDeleteSuccess,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin untuk menghapus leaflet "${leaflet.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                // Store the dialog context before async operation
                final navigator = Navigator.of(context);
                await _deleteLeaflet(
                  context: context,
                  leaflet: leaflet,
                  onDeleteSuccess: onDeleteSuccess,
                );
                navigator.pop(); // Close the dialog
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// Deletes a leaflet from Firestore
  static Future<void> _deleteLeaflet({
    required BuildContext context,
    required Leaflet leaflet,
    required VoidCallback onDeleteSuccess,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      // Show loading indicator
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Menghapus Leaflet...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('leaflets')
          .doc(leaflet.id)
          .delete();
      
      // Show success message using stored context
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Berhasil Menghapus Leaflet!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Call success callback
      onDeleteSuccess();
    } catch (e) {
      // Show error message using stored context
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Gagal Menghapus Leaflet: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Handles the complete delete process including confirmation and navigation
  static Future<void> handleLeafletDelete({
    required BuildContext context,
    required Leaflet leaflet,
  }) async {
    final navigator = Navigator.of(context);
    await showDeleteConfirmationDialog(
      context: context,
      leaflet: leaflet,
      onDeleteSuccess: () {
        // Navigate back to leaflet list after successful deletion
        navigator.pop();
      },
    );
  }
}
//lib\src\features\home\presentation\pages\patient_delete_logic.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientDeleteLogic {
  /// Shows a confirmation dialog for deleting a patient
  static Future<void> showDeleteConfirmationDialog({
    required BuildContext context,
    required String patientId, // <-- SUDAH DIUBAH
    required String patientName,
    required VoidCallback onDeleteSuccess,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // 1. Menambahkan Row dengan Icon peringatan merah
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Konfirmasi Hapus'),
            ],
          ),
          // 2. Mempertegas pesan bahwa ini tindakan permanen
          content: Text(
            'Apakah Anda yakin ingin menghapus data pasien "$patientName" secara permanen? '
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            // 3. Mengubah TextButton menjadi ElevatedButton dengan warna merah
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // Store the dialog context before async operation
                final navigator = Navigator.of(context);
                await _deletePatient(
                  context: context,
                  patientId: patientId,
                  onDeleteSuccess: onDeleteSuccess,
                );
                navigator.pop(); // Close the dialog
              },
              child: const Text('Ya, Hapus'),
            ),
          ],
        );
      },
    );
  }

  /// Deletes a patient from Firestore
  static Future<void> _deletePatient({
    required BuildContext context,
    required String patientId,
    required VoidCallback onDeleteSuccess,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      // Show loading indicator
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Menghapus Data Pasien...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .delete();
      
      // Show success message using stored context
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Berhasil Menghapus Data Pasien!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Call success callback
      onDeleteSuccess();
    } catch (e) {
      // Show error message using stored context
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Gagal Menghapus Data Pasien: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Handles the complete delete process including confirmation and navigation
  static Future<void> handlePatientDelete({
    required BuildContext context,
    required String patientId, // <-- SUDAH DIUBAH
    required String patientName,
  }) async {
    final navigator = Navigator.of(context);
    await showDeleteConfirmationDialog(
      context: context,
      patientId: patientId,
      patientName: patientName,
      onDeleteSuccess: () {
        // Navigate back to patient list after successful deletion
        navigator.pop();
      },
    );
  }
}
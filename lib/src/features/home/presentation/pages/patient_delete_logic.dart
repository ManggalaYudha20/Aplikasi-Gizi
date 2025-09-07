import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/home/data/models/patient_model.dart';

class PatientDeleteLogic {
  /// Shows a confirmation dialog for deleting a patient
  static Future<void> showDeleteConfirmationDialog({
    required BuildContext context,
    required Patient patient,
    required VoidCallback onDeleteSuccess,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin untuk menghapus data pasien "${patient.namaLengkap}" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                // Store the dialog context before async operation
                final navigator = Navigator.of(context);
                await _deletePatient(
                  context: context,
                  patient: patient,
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

  /// Deletes a patient from Firestore
  static Future<void> _deletePatient({
    required BuildContext context,
    required Patient patient,
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
          .doc(patient.id)
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
    required Patient patient,
  }) async {
    final navigator = Navigator.of(context);
    await showDeleteConfirmationDialog(
      context: context,
      patient: patient,
      onDeleteSuccess: () {
        // Navigate back to patient list after successful deletion
        navigator.pop();
      },
    );
  }
}
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
                final dialogContext = context;
                await _deletePatient(
                  context: dialogContext,
                  patient: patient,
                  onDeleteSuccess: onDeleteSuccess,
                );
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
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
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
      
      // Store context before popping
      final scaffoldContext = ScaffoldMessenger.of(context);
      
      // Close dialog first
      Navigator.of(context).pop();
      
      // Show success message using stored context
      scaffoldContext.showSnackBar(
        const SnackBar(
          content: Text('Berhasil Menghapus Data Pasien!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Call success callback
      onDeleteSuccess();
    } catch (e) {
      // Store context before popping
      final scaffoldContext = ScaffoldMessenger.of(context);
      
      // Close dialog first
      Navigator.of(context).pop();
      
      // Show error message using stored context
      scaffoldContext.showSnackBar(
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
    await showDeleteConfirmationDialog(
      context: context,
      patient: patient,
      onDeleteSuccess: () {
        // Navigate back to patient list after successful deletion
        Navigator.of(context).pop();
      },
    );
  }
}
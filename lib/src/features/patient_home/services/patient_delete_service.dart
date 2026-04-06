// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\patient_home\services\patient_delete_service.dart
//
// Dipindahkan dari: presentation/pages/patient_delete_logic.dart
// Perubahan       : Class diubah namanya dari PatientDeleteLogic
//                   menjadi PatientDeleteService agar konsisten dengan
//                   konvensi penamaan folder services/.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientDeleteService {
  /// Menampilkan dialog konfirmasi sebelum menghapus data pasien.
  static Future<void> showDeleteConfirmationDialog({
    required BuildContext context,
    required String patientId,
    required String patientName,
    required VoidCallback onDeleteSuccess,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Konfirmasi Hapus'),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus data pasien "$patientName" secara permanen? ',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _deletePatient(
                  context: context,
                  patientId: patientId,
                  onDeleteSuccess: onDeleteSuccess,
                );
                navigator.pop();
              },
              child: const Text('Ya, Hapus'),
            ),
          ],
        );
      },
    );
  }

  /// Menghapus dokumen pasien dari koleksi Firestore `patients`.
  static Future<void> _deletePatient({
    required BuildContext context,
    required String patientId,
    required VoidCallback onDeleteSuccess,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Menghapus Data Pasien...'),
          duration: Duration(seconds: 1),
        ),
      );

      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .delete();

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Berhasil Menghapus Data Pasien!'),
          backgroundColor: Colors.green,
        ),
      );

      onDeleteSuccess();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Gagal Menghapus Data Pasien: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Entry-point utama: menampilkan dialog konfirmasi lalu navigasi balik
  /// setelah penghapusan berhasil.
  static Future<void> handlePatientDelete({
    required BuildContext context,
    required String patientId,
    required String patientName,
  }) async {
    final navigator = Navigator.of(context);
    await showDeleteConfirmationDialog(
      context: context,
      patientId: patientId,
      patientName: patientName,
      onDeleteSuccess: () {
        navigator.pop();
      },
    );
  }
}

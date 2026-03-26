// lib/src/features/patient_home/presentation/widgets/patient_status_checkbox.dart
//
// Reusable widget yang diekstrak dari kolom "Tandai Selesai" pada:
//   - _buildPatientCard()
//   - _buildPatientAnakCard()
// di patient_home_page.dart.

import 'package:flutter/material.dart';

/// Widget checkbox "Tandai Selesai" yang digunakan di dalam card pasien.
///
/// Contoh penggunaan:
/// ```dart
/// PatientStatusCheckbox(
///   isCompleted: patient.isCompleted,
///   onChanged: () => _togglePatientStatus(patient.id, patient.isCompleted),
/// )
/// ```
class PatientStatusCheckbox extends StatelessWidget {
  /// Status selesai saat ini.
  final bool isCompleted;

  /// Callback yang dipanggil ketika pengguna menekan checkbox.
  /// Logika toggle dikelola oleh parent widget (PatientHomePage).
  final VoidCallback onChanged;

  const PatientStatusCheckbox({
    super.key,
    required this.isCompleted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Tandai Selesai',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              activeColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              value: isCompleted,
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}
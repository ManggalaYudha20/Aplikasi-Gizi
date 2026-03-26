// lib/src/features/patient_home/presentation/widgets/patient_list_card.dart
//
// Berisi dua widget card yang diekstrak dari patient_home_page.dart:
//   - PatientListCard         → untuk pasien dewasa  (ex _buildPatientCard)
//   - PatientAnakListCard     → untuk pasien anak    (ex _buildPatientAnakCard)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_anak_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/presentation/pages/patient_detail_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/presentation/pages/patient_anak_detail_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/presentation/widgets/patient_status_checkbox.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PatientListCard  (Dewasa)
// ─────────────────────────────────────────────────────────────────────────────

/// Card yang menampilkan ringkasan data pasien dewasa di dalam daftar.
///
/// Contoh penggunaan:
/// ```dart
/// PatientListCard(
///   patient: patient,
///   onToggleStatus: () => _togglePatientStatus(patient.id, patient.isCompleted),
/// )
/// ```
class PatientListCard extends StatelessWidget {
  final Patient patient;

  /// Callback yang menangani logika toggle status selesai.
  /// Logika Firestore tetap berada di PatientHomePage.
  final VoidCallback onToggleStatus;

  const PatientListCard({
    super.key,
    required this.patient,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    // ── Status Gizi & Warna ────────────────────────────────────────────────
    Color statusColor = Colors.grey;
    final String statusGizi = patient.monevStatusGizi ?? 'Belum ada status';

    if (statusGizi.contains('Kurang') || statusGizi.contains('Buruk')) {
      statusColor = Colors.orange;
    } else if (statusGizi.contains('Lebih') || statusGizi.contains('Obesitas')) {
      statusColor = Colors.red;
    } else if (statusGizi.contains('Baik') || statusGizi.contains('Normal')) {
      statusColor = Colors.green;
    }

    // ── Format Tanggal & Usia ──────────────────────────────────────────────
    final String formattedDate =
        DateFormat('dd MMM yyyy', 'id_ID').format(patient.tanggalPemeriksaan);

    final DateTime today = DateTime.now();
    int age = today.year - patient.tanggalLahir.year;
    if (patient.tanggalLahir.month > today.month ||
        (patient.tanggalLahir.month == today.month &&
            patient.tanggalLahir.day > today.day)) {
      age--;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: patient.isCompleted ? Colors.green.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: patient.isCompleted
            ? const BorderSide(color: Colors.green, width: 1.5)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  PatientDetailPage(patient: patient),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(-1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                final tween =
                    Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Kiri: Informasi Pasien ───────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              patient.namaLengkap,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            formattedDate,
                            style:
                                TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Text(
                        '${patient.jenisKelamin} | $age Tahun | No.RM: ${patient.noRM}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Diagnosis Medis',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                ),
                                Text(
                                  patient.diagnosisMedis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Status Gizi',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  child: Text(
                                    statusGizi,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Divider Strip ────────────────────────────────────────
                _buildDividerStrip(),

                // ── Kanan: Checkbox ──────────────────────────────────────
                PatientStatusCheckbox(
                  isCompleted: patient.isCompleted,
                  onChanged: onToggleStatus,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PatientAnakListCard  (Anak)
// ─────────────────────────────────────────────────────────────────────────────

/// Card yang menampilkan ringkasan data pasien anak di dalam daftar.
///
/// Contoh penggunaan:
/// ```dart
/// PatientAnakListCard(
///   patient: patientAnak,
///   onToggleStatus: () => _togglePatientStatus(patientAnak.id, patientAnak.isCompleted),
/// )
/// ```
class PatientAnakListCard extends StatelessWidget {
  final PatientAnak patient;

  /// Callback yang menangani logika toggle status selesai.
  final VoidCallback onToggleStatus;

  const PatientAnakListCard({
    super.key,
    required this.patient,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    // ── Status Gizi & Warna ────────────────────────────────────────────────
    Color statusColor = Colors.grey;
    final String statusGizi = patient.statusGiziIMTU ?? 'Belum ada status';

    if (statusGizi.contains('kurang') || statusGizi.contains('buruk')) {
      statusColor = Colors.orange;
    } else if (statusGizi.contains('lebih') || statusGizi.contains('Obesitas')) {
      statusColor = Colors.red;
    } else if (statusGizi.contains('baik') || statusGizi.contains('normal')) {
      statusColor = Colors.green;
    }

    final String formattedDate =
        DateFormat('dd MMM yyyy', 'id_ID').format(patient.tanggalPemeriksaan);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: patient.isCompleted ? Colors.green.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: patient.isCompleted
            ? const BorderSide(color: Colors.green, width: 1.5)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  PatientAnakDetailPage(patient: patient),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(-1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                final tween =
                    Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Kiri: Informasi Pasien Anak ──────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              patient.namaLengkap,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            formattedDate,
                            style:
                                TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Text(
                        '${patient.jenisKelamin} | ${patient.usiaFormatted} | No.RM: ${patient.noRM}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status Gizi Anak:',
                            style: TextStyle(fontSize: 13),
                          ),
                          Text(
                            statusGizi,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Divider Strip ────────────────────────────────────────
                _buildDividerStrip(),

                // ── Kanan: Checkbox ──────────────────────────────────────
                PatientStatusCheckbox(
                  isCompleted: patient.isCompleted,
                  onChanged: onToggleStatus,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Helper
// ─────────────────────────────────────────────────────────────────────────────

/// Strip vertikal dekoratif yang memisahkan konten utama dan checkbox.
Widget _buildDividerStrip() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(8, (_) {
        return Container(
          width: 1.5,
          height: 4,
          color: Colors.grey.shade300,
          margin: const EdgeInsets.symmetric(vertical: 2),
        );
      }),
    ),
  );
}
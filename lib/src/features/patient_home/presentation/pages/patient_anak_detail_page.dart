// lib/src/features/patient_home/presentation/pages/patient_anak_detail_page.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_anak_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/scaffold_with_animated_fab.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'data_form_anak_page.dart'; // Import form anak
import 'patient_delete_logic.dart'; // Import logika hapus
import 'pdf_generator_anak.dart'; // Import PDF generator anak

class PatientAnakDetailPage extends StatefulWidget {
  final PatientAnak patient;

  const PatientAnakDetailPage({super.key, required this.patient});

  @override
  State<PatientAnakDetailPage> createState() => _PatientAnakDetailPageState();
}

class _PatientAnakDetailPageState extends State<PatientAnakDetailPage> {
  late PatientAnak _currentPatient;

  @override
  void initState() {
    super.initState();
    _currentPatient = widget.patient;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithAnimatedFab(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: CustomAppBar(
        title: _currentPatient.namaLengkap,
        subtitle: 'Data Lengkap Pasien Anak',
      ),
      floatingActionButton: FormActionButtons(
        singleButtonMode: false,
        submitText: 'Edit',
        resetText: 'Hapus',
        submitIcon: const Icon(Icons.edit, color: Colors.white),
        resetIcon: const Icon(Icons.delete_forever),
        resetButtonColor: Colors.red,
        submitButtonColor: const Color.fromARGB(255, 0, 148, 68),
        onReset: () {
          // Panggilan ini sekarang sudah benar karena PatientDeleteLogic
          // sudah di-refactor untuk menerima ID dan Nama
          PatientDeleteLogic.handlePatientDelete(
            context: context,
            patientId: _currentPatient.id, // Berikan ID
            patientName: _currentPatient.namaLengkap,
          );
        },
        onSubmit: () async {
          // Navigasi ke form EDIT anak
          final updatedPatient = await Navigator.push<PatientAnak>(
            context,
            MaterialPageRoute(
              builder: (context) => DataFormAnakPage(patient: _currentPatient),
            ),
          );

          if (updatedPatient != null && mounted) {
            setState(() {
              _currentPatient = updatedPatient;
            });
          }
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Data Pasien Anak'),
            _buildInfoRow('No. RM', _currentPatient.noRM),
            _buildInfoRow(
              'Tanggal Lahir',
              _currentPatient.tanggalLahirFormatted,
            ),
            _buildInfoRow('Usia', _currentPatient.usiaFormatted),
            _buildInfoRow('Jenis Kelamin', _currentPatient.jenisKelamin),
            _buildInfoRow('Diagnosis Medis', '${_currentPatient.diagnosisMedis} '),
            _buildInfoRow('Berat Badan', '${_currentPatient.beratBadan} kg'),
            _buildInfoRow(
              'Panjang/Tinggi Badan',
              '${_currentPatient.tinggiBadan.toStringAsFixed(0)} cm',
            ),
            
            const Divider(height: 20, thickness: 2, color: Colors.green),

            _buildSectionTitle('Hasil Status Gizi Anak'),
            // --- 1. BB/U ---
            _buildStatusGiziItem(
              title: 'Berat Badan menurut Umur (BB/U)',
              zScore: _currentPatient.zScoreBB,
              // Gunakan statusGiziAnak jika itu untuk BB/U, atau sesuaikan
              category: _currentPatient.statusGiziAnak,
            ),

            // --- 2. TB/U ---
            _buildStatusGiziItem(
              title: 'Tinggi Badan menurut Umur (TB/U)',
              zScore: _currentPatient.zScoreTB,
              category: _determineHeightCategory(_currentPatient.zScoreTB),
            ),

            // --- 3. BB/TB ---
            _buildStatusGiziItem(
              title: 'Berat Badan menurut Tinggi Badan (BB/TB)',
              zScore: _currentPatient.zScoreBBTB,
              category: _currentPatient.statusGiziBBTB,
            ),

            // --- 4. IMT/U ---
            _buildStatusGiziItem(
              title: 'Indeks Massa Tubuh menurut Umur (IMT/U)',
              zScore: _currentPatient.zScoreIMTU,
              category: _currentPatient.statusGiziIMTU,
            ),
            const Divider(height: 20, thickness: 2, color: Colors.green),

            _buildSectionTitle('Skrining Gizi Lanjut'),
            _buildInfoRow('Skor Status Antropometri', '${_currentPatient.skorAntropometri}'),
            _buildInfoRow('Skor Kehilangan Berat Badan', _currentPatient.kehilanganBeratBadan == 2 ? '2' : '0'),
            _buildInfoRow('Skor Asupan Makanan', '${_currentPatient.kehilanganNafsuMakan ?? 0}'),
            _buildInfoRow('Skor Penyakit Berat', _currentPatient.anakSakitBerat == 2 ? '2' : '0'),
            const Divider(),
            _buildInfoRow('Total Skor', '${_currentPatient.totalPymsScore}', isBold: true),
            _buildInfoRow(
              'Interpretasi',
              _currentPatient.pymsInterpretation,
              isBold: true,
              valueColor: _currentPatient.totalPymsScore >= 2 ? Colors.red : Colors.green,
            ),

            const SizedBox(height: 20),

            // Tombol Cetak PDF Anak
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final scaffoldContext = ScaffoldMessenger.of(context);
                      try {
                        scaffoldContext.showSnackBar(
                          const SnackBar(
                            content: Text('Membuat File PDF...'),
                            duration: Duration(seconds: 1),
                          ),
                        );

                        final pdfFile = await PdfGeneratorAnak.generate(
                          _currentPatient,
                        );

                        await PdfGeneratorAnak.openFile(pdfFile);

                        if (!mounted) return;
                        scaffoldContext.showSnackBar(
                          const SnackBar(
                            content: Text('File PDF Berhasil dibuat!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        scaffoldContext.showSnackBar(
                          SnackBar(
                            content: Text(
                              'File PDF Gagal dibuat: ${e.toString()}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 148, 68),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.picture_as_pdf, size: 20),
                        SizedBox(width: 8),
                        Text('Cetak Formulir Skrining Gizi Anak'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _determineHeightCategory(double? zScore) {
    if (zScore == null) return null;
    if (zScore < -3) return 'Sangat Pendek (severely stunted)';
    if (zScore < -2) return 'Pendek (stunted)';
    if (zScore <= 3) return 'Normal';
    return 'Tinggi';
  }

  Widget _buildStatusGiziItem({
    required String title,
    required double? zScore,
    required String? category,
  }) {
    // Logika Warna Sederhana
    Color statusColor = Colors.red;
    if (category != null) {
      if (category.toLowerCase().contains('baik') ||
          category.toLowerCase().contains('normal')) {
        statusColor = Colors.green;
      } else if (category.toLowerCase().contains('kurang') ||
          category.toLowerCase().contains('buruk') ||
          category.toLowerCase().contains('pendek') ||
          category.toLowerCase().contains('sangat pendek') ||
          category.toLowerCase().contains('gizi buruk')) {
        statusColor = Colors.red;
      } else if (category.toLowerCase().contains('lebih') ||
          category.toLowerCase().contains('resiko')) {
        statusColor = Colors.orange;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Keterangan / Judul
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 2. Z-Score
              Row(
                children: [
                  const Text(
                    'Z-Score: ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    zScore?.toStringAsFixed(2) ?? '-',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),

              // 3. Kategori (Badge Berwarna)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  category ?? 'Belum ada data',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // (Copy/paste _buildSectionTitle dan _buildInfoRow dari patient_detail_page.dart)
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 0, 148, 68),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

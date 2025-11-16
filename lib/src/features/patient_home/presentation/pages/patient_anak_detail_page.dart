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
            _buildInfoRow('Tanggal Lahir', _currentPatient.tanggalLahirFormatted),
            _buildInfoRow('Usia', _currentPatient.usiaFormatted),
            _buildInfoRow('Jenis Kelamin', _currentPatient.jenisKelamin),
            _buildInfoRow('Berat Badan', '${_currentPatient.beratBadan} kg'),
            _buildInfoRow('Panjang/Tinggi Badan',
                '${_currentPatient.tinggiBadan.toStringAsFixed(0)} cm'),
            if (_currentPatient.lila != null)
              _buildInfoRow(
                  'LILA', '${_currentPatient.lila!.toStringAsFixed(1)} cm'),
            const Divider(height: 20, thickness: 2, color: Colors.green),
            _buildSectionTitle('Hasil Perhitungan Gizi Anak'),
            _buildInfoRow('Status Gizi', _currentPatient.statusGiziAnak ?? '-',
                isBold: true),
            _buildInfoRow(
                'Z-Score BB/U', _currentPatient.zScoreBB?.toStringAsFixed(2) ?? '-'),
            _buildInfoRow(
                'Z-Score TB/U', _currentPatient.zScoreTB?.toStringAsFixed(2) ?? '-'),
            const SizedBox(height: 20),

            // Tombol Cetak PDF Anak
            ElevatedButton(
              onPressed: () async {
                // --- INI ADALAH IMPLEMENTASI DARI TODO ---
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
                // --- AKHIR DARI IMPLEMENTASI TODO ---
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Cetak Formulir Gizi Anak',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),

            // (Tampilkan data asuhan gizi anak jika ada)
          ],
        ),
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

  Widget _buildInfoRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
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
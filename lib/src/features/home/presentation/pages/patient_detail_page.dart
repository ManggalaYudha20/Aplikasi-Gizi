import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/home/data/models/patient_model.dart';
import 'pdf_generator.dart';
import 'patient_delete_logic.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'data_form_page.dart';
import 'pdf_generator_asuhan.dart';

class PatientDetailPage extends StatefulWidget {
  final Patient patient;

  const PatientDetailPage({super.key, required this.patient});

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  late Patient _currentPatient;

  @override
  void initState() {
    super.initState();
    _currentPatient = widget.patient;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: CustomAppBar(
        title: _currentPatient.namaLengkap,
        subtitle: 'Data Lengkap Pasien',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Bagian Data Pasien ---
            _buildSectionTitle('Data Pasien'),
            _buildInfoRow('No. RM', _currentPatient.noRM),
            _buildInfoRow(
              'Tanggal Lahir',
              _currentPatient.tanggalLahirFormatted,
            ),
            _buildInfoRow('Usia', '${_currentPatient.usia} tahun'),
            _buildInfoRow('Jenis Kelamin', _currentPatient.jenisKelamin),
            _buildInfoRow(
              'Berat Badan',
            '${_currentPatient.beratBadan} kg',
            ),
            _buildInfoRow(
              'Tinggi Badan',
            '${_currentPatient.tinggiBadan.toStringAsFixed(0)} cm',
            ),
            if (_currentPatient.lila != null)
              _buildInfoRow(
                'Lingkar Lengan Atas (LILA)',
                '${_currentPatient.lila!.toStringAsFixed(1)} cm',
              ),
            if (_currentPatient.tl != null)
              _buildInfoRow(
                'Tinggi Lutut (TL)',
                '${_currentPatient.tl!.toStringAsFixed(1)} cm',
              ),
            _buildInfoRow('Diagnosis Medis', _currentPatient.diagnosisMedis),

            const Divider(
              height: 20,
              thickness: 2,
              color: Colors.green,
            ),

            // --- Bagian Hasil Perhitungan Gizi ---
            _buildSectionTitle('Hasil Perhitungan Gizi'),
            _buildInfoRow(
              'IMT (Indeks Massa Tubuh)',
              '${_currentPatient.imt.toStringAsFixed(2)} kg/m²',
              isBold: true,
            ),
            _buildInfoRow(
              'BBI (Berat Badan Ideal)',
              _currentPatient.bbi != 0.0 ? '${_currentPatient.bbi.toStringAsFixed(1)} kg' : '-',
              isBold: true,
            ),
            _buildInfoRow(
              'BMR (Kebutuhan Kalori Basal)',
              _currentPatient.bmr != 0.0 ? '${_currentPatient.bmr.toStringAsFixed(2)} kkal' : '-',
              isBold: true,
            ),
            _buildInfoRow(
              'TDEE (Total Kebutuhan Energi)',
              _currentPatient.tdee != 0.0 ? '${_currentPatient.tdee.toStringAsFixed(2)} kkal' : '-',
              isBold: true,
            ),
            _buildInfoRow('Aktivitas', _currentPatient.aktivitas),

            const Divider(
              height: 20,
              thickness: 2,
              color: Colors.green,
            ),

            // --- Bagian Skrining Gizi Lanjut ---
            _buildSectionTitle('Skrining Gizi Lanjut'),
            _buildInfoRow('Skor IMT', _currentPatient.skorIMT.toString()),
            _buildInfoRow(
              'Skor Kehilangan BB',
              _currentPatient.skorKehilanganBB.toString(),
            ),
            _buildInfoRow(
              'Skor Efek Penyakit Akut',
              _currentPatient.skorEfekPenyakit.toString(),
            ),
            const Divider(),
            _buildInfoRow(
              'Total Skor',
              _currentPatient.totalSkor.toString(),
              isBold: true,
            ),
            _buildInfoRow(
              'Interpretasi',
              _currentPatient.interpretasi,
              isBold: true,
              valueColor: Colors.red,
            ),

            const SizedBox(height: 20),

            // --- Tombol Aksi ---
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

                        final pdfFile = await PdfGenerator.generate(
                          _currentPatient,
                        );

                        await PdfGenerator.openFile(pdfFile);

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
                        Text('Formulir Skrining Gizi'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

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

                        final pdfFile = await PdfGeneratorAsuhan.generate(
                          _currentPatient,
                        );

                        await PdfGeneratorAsuhan.openFile(pdfFile);

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
                      backgroundColor: Colors.blue,
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
                        Text('Formulir Asuhan Gizi'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            FormActionButtons(
              singleButtonMode: false,
              submitText: 'Edit',
              resetText: 'Hapus',
              submitIcon: const Icon(Icons.edit, color: Colors.white),
              resetIcon: const Icon(Icons.delete_forever, color: Colors.red),
              resetButtonColor: Colors.red,
              submitButtonColor: const Color.fromARGB(255, 0, 148, 68),
              onReset: () {
                PatientDeleteLogic.handlePatientDelete(
                  context: context,
                  patient: _currentPatient,
                );
              },
              onSubmit: () async {
                final updatedPatient = await Navigator.push<Patient>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DataFormPage(patient: _currentPatient),
                  ),
                );

                if (updatedPatient != null && mounted) {
                  setState(() {
                    _currentPatient = updatedPatient;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

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
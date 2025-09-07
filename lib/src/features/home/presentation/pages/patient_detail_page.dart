import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/home/data/models/patient_model.dart'; // Impor model pasien
import 'pdf_generator.dart'; // Helper untuk membuat PDF
import 'patient_delete_logic.dart'; // Separate delete logic
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'data_form_page.dart'; // Import the data form page for editing

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
            _buildInfoRow('Tanggal Lahir', _currentPatient.tanggalLahirFormatted),
            _buildInfoRow('Usia', '${_currentPatient.usia} tahun'),
            _buildInfoRow('Jenis Kelamin', _currentPatient.jenisKelamin),
            _buildInfoRow('Diagnosis Medis', _currentPatient.diagnosisMedis),

            const SizedBox(height: 20),

            // --- Bagian Hasil Perhitungan Gizi ---
            _buildSectionTitle('Hasil Perhitungan Gizi'),
            _buildInfoRow('Berat Badan', '${_currentPatient.beratBadan} kg'),
            _buildInfoRow(
              'Tinggi Badan',
              '${_currentPatient.tinggiBadan.toStringAsFixed(0)} cm',
            ),
            _buildInfoRow(
              'IMT (Indeks Massa Tubuh)',
              '${_currentPatient.imt.toStringAsFixed(2)} kg/m²',
              isBold: true,
            ),
            _buildInfoRow(
              'BBI (Berat Badan Ideal)',
              '${_currentPatient.bbi.toStringAsFixed(1)} kg',
              isBold: true,
            ),
            _buildInfoRow(
              'BMR (Kebutuhan Kalori Basal)',
              '${_currentPatient.bmr.toStringAsFixed(2)} kkal',
              isBold: true,
            ),
            _buildInfoRow(
              'TDEE (Total Kebutuhan Energi)',
              '${_currentPatient.tdee.toStringAsFixed(2)} kkal',
              isBold: true,
            ),
            _buildInfoRow('Aktivitas', _currentPatient.aktivitas),

            const SizedBox(height: 20),

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
                      // Store context before async operation
                        final scaffoldContext = ScaffoldMessenger.of(context);

                      try {            
                        // Show loading indicator
                        scaffoldContext.showSnackBar(
                          const SnackBar(
                            content: Text('Membuat File PDF...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        
                        // Generate PDF
                        final pdfFile = await PdfGenerator.generate(_currentPatient);
                        
                        // Open the PDF file
                        await PdfGenerator.openFile(pdfFile);
                        
                        // Show success message
                        if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('File PDF Berhasil dibuat!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        
                      } catch (e) {
                        // Show error message
                        if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('File PDF Gagal dibuat: ${e.toString()}'),
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
                        Text('Simpan sebagai PDF'),
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
                // Delete functionality using separate logic
                PatientDeleteLogic.handlePatientDelete(
                  context: context,
                  patient: _currentPatient,
                );
              },
              onSubmit: () async {
                // Navigate to edit page with patient data and wait for result
                final updatedPatient = await Navigator.push<Patient>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DataFormPage(patient: widget.patient),
                  ),
                );
                
                // If patient data was updated, refresh the UI
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

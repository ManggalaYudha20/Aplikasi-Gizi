// lib/src/features/home/presentation/pages/patient_detail_page.dart
import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/home/data/models/patient_model.dart'; // Impor model pasien
import 'pdf_generator.dart'; // Helper untuk membuat PDF

class PatientDetailPage extends StatelessWidget {
  final Patient patient;

  const PatientDetailPage({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(patient.namaLengkap),
        backgroundColor: const Color.fromARGB(255, 0, 148, 68),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Bagian Data Pasien ---
            _buildSectionTitle('Data Pasien'),
            _buildInfoRow('No. RM', patient.noRM),
            _buildInfoRow('Tanggal Lahir', patient.tanggalLahirFormatted),
            _buildInfoRow('Usia', '${patient.usia} tahun'),
            _buildInfoRow('Jenis Kelamin', patient.jenisKelamin),
            _buildInfoRow('Diagnosis Medis', patient.diagnosisMedis),
            
            const SizedBox(height: 20),

            // --- Bagian Hasil Perhitungan Gizi ---
            _buildSectionTitle('Hasil Perhitungan Gizi'),
            _buildInfoRow('Berat Badan', '${patient.beratBadan} kg'),
            _buildInfoRow('Tinggi Badan', '${patient.tinggiBadan} cm'),
            _buildInfoRow('IMT (Indeks Massa Tubuh)', patient.imt.toStringAsFixed(1), isBold: true),
            _buildInfoRow('BBI (Berat Badan Ideal)', '${patient.bbi.toStringAsFixed(1)} kg', isBold: true),
            _buildInfoRow('BMR (Kebutuhan Kalori Basal)', '${patient.bmr.toStringAsFixed(1)} kkal', isBold: true),
            _buildInfoRow('TDEE (Total Kebutuhan Energi)', '${patient.tdee.toStringAsFixed(1)} kkal', isBold: true),
            _buildInfoRow('Aktivitas', patient.aktivitas),

            const SizedBox(height: 20),

            // --- Bagian Skrining Gizi Lanjut ---
            _buildSectionTitle('Skrining Gizi Lanjut'),
            _buildInfoRow('Skor IMT', patient.skorIMT.toString()),
            _buildInfoRow('Skor Kehilangan BB', patient.skorKehilanganBB.toString()),
            _buildInfoRow('Skor Efek Penyakit Akut', patient.skorEfekPenyakit.toString()),
            const Divider(),
            _buildInfoRow('Total Skor', patient.totalSkor.toString(), isBold: true),
            _buildInfoRow('Interpretasi', patient.interpretasi, isBold: true, valueColor: Colors.red),

            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final pdfFile = await PdfGenerator.generate(patient);
          PdfGenerator.openFile(pdfFile);
        },
        label: const Text('Save as PDF'),
        icon: const Icon(Icons.picture_as_pdf),
        backgroundColor: const Color.fromARGB(255, 0, 148, 68),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 148, 68)),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
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
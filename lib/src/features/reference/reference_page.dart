import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';

class ReferencePage extends StatelessWidget {
  const ReferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(title: 'Referensi', subtitle: 'Sumber Data dan Rumus Perhitungan'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Sumber Data'),
            const SizedBox(height: 10),
            _buildDataSourceCard(
              title: 'Tabel Komposisi Pangan Indonesia (TKPI) 2019',
              description: 'Data nilai gizi makanan yang digunakan dalam aplikasi ini bersumber dari TKPI 2019 yang diterbitkan oleh Kementerian Kesehatan Republik Indonesia.',
              icon: Icons.table_chart,
            ),
            const SizedBox(height: 10),
            _buildDataSourceCard(
              title: 'Angka Kecukupan Gizi (AKG)',
              description: 'Standar kebutuhan gizi harian berdasarkan peraturan Kementerian Kesehatan yang berlaku.',
              icon: Icons.accessibility_new,
            ),
            
            const SizedBox(height: 25),
            _buildSectionTitle('Rumus Perhitungan'),
            const SizedBox(height: 10),
            
            // Rumus BBI
            _buildFormulaTile(
              title: 'Berat Badan Ideal (BBI)',
              formulaName: 'Rumus Broca (Modifikasi)',
              formula: 'Tinggi Badan (cm) - 100 - ((TB - 100) x 10%)',
              note: 'Untuk pria < 160cm dan wanita < 150cm, potongan 10% tidak diberlakukan.',
            ),

            // Rumus IMT
            _buildFormulaTile(
              title: 'Indeks Massa Tubuh (IMT)',
              formulaName: 'Standar WHO / Kemenkes',
              formula: 'Berat Badan (kg) / (Tinggi Badan (m) x Tinggi Badan (m))',
              note: 'Kategori: Kurus (<18.5), Normal (18.5-25.0), Gemuk (>25.0).',
            ),

            // Rumus BMR
            _buildFormulaTile(
              title: 'Kebutuhan Energi Basal (BMR)',
              formulaName: 'Rumus Harris-Benedict (Revisi 1990)',
              formula: 'Pria: (10 x BB) + (6.25 x TB) - (5 x Usia) + 5\nWanita: (10 x BB) + (6.25 x TB) - (5 x Usia) - 161',
              note: 'Digunakan untuk menghitung kalori minimal yang dibutuhkan tubuh saat istirahat.',
            ),

            // Rumus TDEE
            _buildFormulaTile(
              title: 'Total Daily Energy Expenditure (TDEE)',
              formulaName: 'Faktor Aktivitas Fisik',
              formula: 'BMR x Faktor Aktivitas',
              note: 'Faktor aktivitas berkisar dari 1.2 (sedenter) hingga 1.9 (sangat aktif).',
            ),
            
            // Penyakit Ginjal (Contoh jika ada)
            _buildFormulaTile(
              title: 'Diet Penyakit Ginjal',
              formulaName: 'Perhitungan Protein',
              formula: 'Disesuaikan dengan stadium CKD (0.6 - 0.8 g/kg BB)',
              note: 'Mengacu pada panduan asuhan gizi terstandar (PAGT).',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.teal,
      ),
    );
  }

  Widget _buildDataSourceCard({required String title, required String description, required IconData icon}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.teal, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulaTile({required String title, required String formulaName, required String formula, required String note}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          formulaName,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Rumus:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formula,
                    // Menggunakan font family monospace agar terlihat seperti rumus/kode
                    style: const TextStyle(
                      fontSize: 13, 
                      color: Colors.black87,
                      fontFamily: 'monospace', 
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Catatan:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  note,
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
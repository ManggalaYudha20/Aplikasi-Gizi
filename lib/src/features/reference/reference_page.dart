import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';

// Import file yang telah dipisahkan
import 'reference_data.dart';
import 'reference_widgets.dart';

class ReferencePage extends StatelessWidget {
  const ReferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Referensi',
        subtitle: 'Sumber Data dan Rumus Perhitungan',
      ),
      body: Scrollbar(
        thumbVisibility: false,
        thickness: 6.0,
        radius: const Radius.circular(10),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, 'Sumber Data'),
              const SizedBox(height: 10),
              
              // Mapping Data Sources dari reference_data.dart
              ...ReferenceData.dataSources.map((source) => DataSourceCard(
                // Menggunakan ID dari model sebagai Key
                key: ValueKey(source.id), 
                semanticId: source.id,
                title: source.title,
                description: source.description,
                icon: source.icon,
              )),

              const SizedBox(height: 25),
              _buildSectionTitle(context, 'Rumus Perhitungan'),
              const SizedBox(height: 10),

              // Bagian Rumus (Content UI tetap didefinisikan di sini karena kompleksitas visual)
              // Namun dibungkus dalam widget FormulaTile yang reusable
              
              _buildProteinFormula(context),

              FormulaTile(
                semanticId: 'formula_perkeni',
                title: 'Kebutuhan Kalori Diet DM',
                formulaName: 'Metode PERKENI 2024',
                formulaContent: const Text(
                  'Total = (BBI x Kalori Basal) + Aktivitas - Usia +/- Koreksi BB +/- Stress Metabolik',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                note: 'Sumber: Pedoman Pengelolaan dan Pencegahan Diabetes Melitus Tipe 2 Dewasa di Indonesia 2024, Hal. 53-54.\n\n'
                    'Rincian Faktor:\n'
                    '• Kalori Basal: Pria (30 kal/kg BBI), Wanita (25 kal/kg BBI)\n'
                    '• Koreksi Usia: 40-59 th (-5%), 60-69 th (-10%), >70 th (-20%)\n'
                    '• Aktivitas: Ringan (+20%), Sedang (+30%), Berat (+40%)\n'
                    '• Status Gizi: Gemuk (-20% s/d -30%), Kurus (+20% s/d +30%)',
              ),

              FormulaTile(
                semanticId: 'formula_broca',
                title: 'Berat Badan Ideal (BBI)',
                formulaName: 'Rumus Broca (Modifikasi)',
                formulaContent: const Text(
                  '(a) (Tinggi Badan (cm) - 100) - 10%) \n(b) (Tinggi Badan (cm) - 100)',
                  style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
                note: 'Pada persamaan (a) digunakan Bagi pria dengan tinggi badan ≥ 160 cm dan wanita dengan tinggi badan ≥ 150 cm. sedangkan Bagi pria dengan tinggi badan < 160 cm dan wanita dengan tinggi badan < 150 cm menggunakan persamaan (b)',
              ),

               FormulaTile(
                semanticId: 'formula_bbi_anak',
                title: 'Berat Badan Ideal (Anak)',
                formulaName: 'Usia < 12 tahun',
                formulaContent: const Text(
                  '0 - 11 bulan: \nDBW = a + 9 / 2 atau a/2 + 3 s/d 4\n\n1 - 6 tahun: \nBBI = 2n + 8\n\n7 - 12 tahun: \nBBI = 7n-5/2',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                note: 'a = usia dalam bulan\nn = usia dalam tahun',
              ),

              FormulaTile(
                semanticId: 'formula_imt',
                title: 'Indeks Massa Tubuh (IMT)',
                formulaName: 'Standar WHO / Kemenkes',
                formulaContent: const FractionText(
                  'Berat Badan (kg)',
                  'Tinggi Badan (m) x Tinggi Badan (m)',
                ),
                note: 'Kategori: Kurus (<18.5), Normal (18.5-25.0), Gemuk (>25.0).',
              ),
              
              FormulaTile(
                semanticId: 'formula_bmr',
                title: 'Basal Metabolic Rate (BMR)',
                formulaName: 'Kebutuhan Energi Basal',
                formulaContent: const Text(
                  'Persamaan Harris-Benedict :\n'
                  'Pria: 66,47+(13,75 x BB)+(5,003 x TB)-(6,755 x U)\n\n'
                  'Wanita: 655,1+(9,563 x BB)+(1,850 x TB)-(4,676xU)\n\n'
                  'Persamaan Mifflin-St Jeor :\n'
                  'Pria: 5+(9,99 x BB)+(6,25 x TB)-(4,92 x U)\n\n'
                  'Wanita: 161-(9,99 x BB)+(6,25 x TB)-(4,92 x U)',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
                note: 'BB = Berat Badan (kg)\nTB = Tinggi Badan (cm)\nU = Usia (Tahun)',
              ),

               FormulaTile(
                semanticId: 'formula_tdee',
                title: 'Total Daily Energy Expenditure (TDEE)',
                formulaName: 'Faktor Aktivitas Fisik',
                formulaContent: const Text(
                  'BMR x Faktor Aktivitas x Faktor Stress',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                note: 'TDEE adalah perkiraan jumlah total kalori yang dibakar oleh tubuh dalam satu hari (24 jam).',
              ),

              const SizedBox(height: 25),
              _buildSectionTitle(context, 'Tabel Referensi'),
              const SizedBox(height: 10),

              // Mapping Tables dari reference_data.dart
              ...ReferenceData.referenceTables.map((table) => ReferenceTableWidget(
                key: ValueKey(table.id),
                semanticId: table.id,
                title: table.title,
                subtitle: table.subtitle,
                headers: table.headers,
                data: table.data,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // Refactor khusus untuk formula Protein Ginjal karena UI-nya custom (colored boxes)
  Widget _buildProteinFormula(BuildContext context) {
    return FormulaTile(
      semanticId: 'formula_ginjal',
      title: 'Kebutuhan Protein (Ginjal Kronik)',
      formulaName: 'Rumus Perhitungan (Berdasarkan BBI)',
      formulaContent: Column(
        children: [
          const Text(
            'Pasien Pradialisis (Belum HD)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          _buildColoredFormulaBox(
            context,
            'Total Protein = (0,6 s/d 0,8) x BBI',
            Colors.orange,
          ),
          const SizedBox(height: 12),
          const Text(
            'Pasien Hemodialisis (HD Rutin)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          _buildColoredFormulaBox(
             context,
            'Total Protein = (1,2) x BBI',
            Colors.red,
          ),
        ],
      ),
      note:
          'Keterangan:\n'
          '• BBI = Berat Badan Ideal (dihitung dengan rumus Broca).\n'
          '• Rumus ini memastikan ginjal tidak bekerja terlalu berat akibat kelebihan protein dari berat badan aktual (jika pasien obesitas/edema).\n'
          '• Min. 50% protein harus bernilai biologis tinggi (telur, daging, ikan).',
    );
  }

  Widget _buildColoredFormulaBox(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
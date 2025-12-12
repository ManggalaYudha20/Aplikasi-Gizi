import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';

class ReferencePage extends StatelessWidget {
  const ReferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(
        title: 'Referensi',
        subtitle: 'Sumber Data dan Rumus Perhitungan',
      ),
      // 1. Tambahkan Widget Scrollbar di sini
      body: Scrollbar(
        // thumbVisibility: false membuat scrollbar otomatis hilang saat tidak discroll (default di mobile)
        thumbVisibility: false,
        thickness: 6.0, // Ketebalan scrollbar (opsional)
        radius: const Radius.circular(
          10,
        ), // Sudut scrollbar membulat (opsional)
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Sumber Data'),
              const SizedBox(height: 10),
              _buildDataSourceCard(
                title: 'Tabel Komposisi Pangan Indonesia (TKPI) 2020',
                description:
                    'Data nilai gizi makanan yang digunakan dalam aplikasi ini bersumber dari TKPI 2020 yang diterbitkan oleh Kementerian Kesehatan Republik Indonesia.',
                icon: Icons.table_chart,
              ),
              const SizedBox(height: 10),
              _buildDataSourceCard(
                title: 'Standar Antropometri Penilaian Status Gizi Anak',
                description:
                    'Acuan standar antropometri untuk penilaian status gizi anak berdasarkan Keputusan Menteri Kesehatan Republik Indonesia Nomor: 1995/MENKES/SK/XII/2010.',
                icon: Icons.child_care,
              ),
              const SizedBox(height: 10),
              _buildDataSourceCard(
                title: 'Penatalaksanaan Diet Pada Pasien',
                description:
                    'Penulis : Retno Wahyuningsih, S.Gz.\nEdisi Pertama - Yogyakarta; Graha Ilmu, 2013\nxiv + 244 halaman, 1 jilid : 26 cm\nISBN: 978-602-262-065-5',
                icon: Icons.book,
              ),
              const SizedBox(height: 10),
              _buildDataSourceCard(
                title: 'Penuntun Diet dan Terapi Gizi',
                description:
                    'Penulis : Persatuan Ahli Gizi Indonesia & Asosiasi Dietisen indonesia\nEdisi Kelima - Jakarta; EGC, 2025\nxxiii + 520 halaman : ilustrasi; 15,5 cm x 24 cm\nISBN: 978-623-203-625-3',
                icon: Icons.book,
              ),
              _buildDataSourceCard(
                title:
                    'Pedoman Pengelolaan dan Pencegahan Diabetes Melitus Tipe 2 Dewasa di Indonesia 2024',
                description:
                    'Penulis: Perkumpulan Endokrinologi Indonesia (PERKENI)\n'
                    'Tahun: 2024\n'
                    'Diterbitkan oleh: PB PERKENI',
                icon: Icons.local_library,
              ),
              

              const SizedBox(height: 25),
              _buildSectionTitle('Rumus Perhitungan'),
              const SizedBox(height: 10),

              _buildFormulaTile(
                title: 'Kebutuhan Protein (Ginjal Kronik)',
                formulaName: 'Rumus Perhitungan (Berdasarkan BBI)',
                formula: Column(
                  children: [
                    const Text(
                      'Pasien Pradialisis (Belum HD)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Total Protein = (0,6 s/d 0,8) x BBI',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pasien Hemodialisis (HD Rutin)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Total Protein = (1,2) x BBI',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                note:
                    'Keterangan:\n'
                    '• BBI = Berat Badan Ideal (dihitung dengan rumus Broca).\n'
                    '• Rumus ini memastikan ginjal tidak bekerja terlalu berat akibat kelebihan protein dari berat badan aktual (jika pasien obesitas/edema).\n'
                    '• Min. 50% protein harus bernilai biologis tinggi (telur, daging, ikan).',
              ),

              _buildFormulaTile(
                title: 'Kebutuhan Kalori Diet DM',
                formulaName: 'Metode PERKENI 2024',
                formula: const Text(
                  'Total = (BBI x Kalori Basal) + %Aktivitas - %Usia +/- %Koreksi BB',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                note:
                    'Sumber: Pedoman Pengelolaan dan Pencegahan Diabetes Melitus Tipe 2 Dewasa di Indonesia 2024, Hal. 53-54.\n\n'
                    'Rincian Faktor:\n'
                    '• Kalori Basal: Pria (30 kal/kg BBI), Wanita (25 kal/kg BBI)\n'
                    '• Koreksi Usia: 40-59 th (-5%), 60-69 th (-10%), >70 th (-20%)\n'
                    '• Aktivitas: Ringan (+20%), Sedang (+30%), Berat (+40%)\n'
                    '• Status Gizi: Gemuk (-20% s/d -30%), Kurus (+20% s/d +30%)',
              ),

              // Rumus BBI
              _buildFormulaTile(
                title: 'Berat Badan Ideal (BBI)',
                formulaName: 'Rumus Broca (Modifikasi)',
                formula: const Text(
                  '(a) (Tinggi Badan (cm) - 100) - 10%) \n(b) (Tinggi Badan (cm) - 100)',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                note:
                    'Pada persamaan (a) digunakan Bagi pria dengan tinggi badan ≥ 160 cm dan wanita dengan tinggi badan ≥ 150 cm. sedangkan Bagi pria dengan tinggi badan < 160 cm dan wanita dengan tinggi badan < 150 cm menggunakan persamaan (b)',
              ),
              _buildFormulaTile(
                title: 'Berat Badan Ideal',
                formulaName: 'Usia < 12 tahun',
                formula: const Text(
                  '0 - 11 bulan: \nDBW = a + 9 / 2 atau a/2 + 3 s/d 4\n\n1 - 6 tahun: \nBBI = 2n + 8\n\n7 - 12 tahun: \nBBI = 7n-5/2',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                note: 'a = usia dalam bulan\nn = usia dalam tahun',
              ),

              // Rumus IMT
              _buildFormulaTile(
                title: 'Indeks Massa Tubuh (IMT)',
                formulaName: 'Standar WHO / Kemenkes',
                formula: _buildFraction(
                  'Berat Badan (kg)',
                  'Tinggi Badan (m) x Tinggi Badan (m)',
                ),
                note:
                    'Kategori: Kurus (<18.5), Normal (18.5-25.0), Gemuk (>25.0).',
              ),

              // Rumus BMR
              _buildFormulaTile(
                title: 'Basal Metabolic Rate (BMR)',
                formulaName: 'Kebutuhan Energi Basal',
                formula: const Text(
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
                note:
                    'BB = Berat Badan (kg)\nTB = Tinggi Badan (cm)\nU = Usia (Tahun)',
              ),

              // Rumus TDEE
              _buildFormulaTile(
                title: 'Total Daily Energy Expenditure (TDEE)',
                formulaName: 'Faktor Aktivitas Fisik',
                formula: const Text(
                  'BMR x Faktor Aktivitas x Faktor Stress',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                note:
                    'TDEE adalah perkiraan jumlah total kalori yang dibakar oleh tubuh dalam satu hari (24 jam).',
              ),

              const SizedBox(height: 25),
              _buildSectionTitle('Tabel Referensi'),
              const SizedBox(height: 10),
              _buildReferenceTable(
                title: 'Faktor Aktivitas',
                headers: ['Tingkat Aktivitas', 'Faktor Aktivitas'],
                data: [
                  ['Sangat jarang', '1,2'],
                  ['Aktivitas Ringan', '1,375'],
                  ['Aktivitas Sedang', '1,55'],
                  ['Aktivitas Berat', '1,725'],
                  ['Sangat Aktif', '1,9'],
                ],
              ),

              _buildReferenceTable(
                title: 'Faktor Stress',
                headers: ['Tingkat Stress', 'Faktor Stress'],
                data: [
                  ['Demam', '0,13 per 1°C'],
                  ['Peritonitis', '1,2 - 1,5'],
                  ['Cedera jaringan lunak', '1,14 - 1,37'],
                  ['Patah tulang multiple', '1,2 - 1,35'],
                  ['Sepsis', '1,4 - 1,8'],
                  ['Luka bakar 0-20°C', '1,0 - 1,5'],
                  ['Luka bakar 20-40°C', '1,5 - 1,85'],
                  ['Luka bakar 40-100°C', '1,85 - 2,05'],
                  ['Puasa', '0,7'],
                  ['Payah gagal jantung', '1,3 - 1,5'],
                  ['kanker', '1,3'],
                ],
              ),

              _buildReferenceTable(
                title: 'Penilaian IMT Indonesia',
                subtitle: 'Standar Indonesia (Depkes RI, 2003)',
                headers: ['Status Gizi', 'IMT (kg/m²)'],
                data: [
                  ['Kurus Sekali', '< 17.0'],
                  ['Kurus', '17.0 - 18.4'],
                  ['Normal', '18.5 - 25.0'],
                  ['Gemuk', '25.1 - 27.0'],
                  ['Gemuk Sekali', '> 27.0'],
                ],
              ),

              _buildReferenceTable(
                title: 'Penilaian IMT Asia',
                subtitle: 'Standar Asia Pasifik',
                headers: ['Status Gizi', 'IMT (kg/m²)'],
                data: [
                  ['BB Kurang', '< 18.5'],
                  ['BB Normal', '18.5 - 22.9'],
                  ['BB Lebih', '≥ 23.0'],
                  ['Dengan Resiko', '23.0 - 24.9'],
                  ['Obes I', '25.0 - 29.9'],
                  ['Obes II', '> 30'],
                ],
              ),

              _buildReferenceTable(
                title: 'Penilaian IMT Eropa',
                subtitle: 'Standar Eropa (WHO, 1995)',
                headers: ['Status Gizi', 'IMT (kg/m²)'],
                data: [
                  ['Kurus', '< 18.5'],
                  ['Normal', '18.5 - 24.9'],
                  ['Kegemukan', '≥ 25'],
                  ['Pre Obes', '25.0 - 29.9'],
                  ['Obes I', '30.0 - 34.9'],
                  ['Obes II', '35.0 - 39.9'],
                  ['Obes III', '≥ 40'],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceTable({
    required String title,
    required List<String> headers,
    required List<List<String>> data,
    String? subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          subtitle ?? "Klik untuk melihat tabel",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Table(
              border: TableBorder.all(
                color: Colors.grey.shade300,
                width: 1,
                borderRadius: BorderRadius.circular(8),
              ),
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(0.8),
              },
              children: [
                // --- Header Row ---
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  children: headers.map((header) {
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        header,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }).toList(),
                ),

                // --- Data Rows ---
                ...data.map((row) {
                  return TableRow(
                    children: row.map((cellData) {
                      return Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          cellData,
                          style: const TextStyle(fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
    );
  }

  Widget _buildDataSourceCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.green, size: 30),
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
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulaTile({
    required String title,
    required String formulaName,
    required Widget formula,
    required String note,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
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
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: formula),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Catatan:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  note,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFraction(String atas, String bawah) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          atas,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          height: 1.5,
          width: double.infinity,
          color: Colors.black87,
        ),
        Text(
          bawah,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

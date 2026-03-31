import 'package:flutter/material.dart';
import '../../widgets/reference_widgets.dart';

// --- Models ---

class DataSourceItem {
  final String id; // ID unik untuk QA
  final String title;
  final String description;
  final IconData icon;

  const DataSourceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class ReferenceTableItem {
  final String id; // ID unik untuk QA
  final String title;
  final String? subtitle;
  final List<String> headers;
  final List<List<String>> data;

  const ReferenceTableItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.headers,
    required this.data,
  });
}

class FormulaItem {
  final String id;
  final String title;
  final String formulaName;
  final Widget formulaContent;
  final String note;

  const FormulaItem({
    required this.id,
    required this.title,
    required this.formulaName,
    required this.formulaContent,
    required this.note,
  });
}

// --- Static Data ---

class ReferenceData {
  // Data Sumber Pustaka
  static const List<DataSourceItem> dataSources = [
    DataSourceItem(
      id: 'source_tkpi',
      title: 'Tabel Komposisi Pangan Indonesia (TKPI) 2020',
      description:
          'Data nilai gizi makanan yang digunakan dalam aplikasi ini bersumber dari TKPI 2020 yang diterbitkan oleh Kementerian Kesehatan Republik Indonesia.',
      icon: Icons.table_chart,
    ),
    DataSourceItem(
      id: 'source_antropometri',
      title: 'Standar Antropometri Penilaian Status Gizi Anak',
      description:
          'Acuan standar antropometri untuk penilaian status gizi anak berdasarkan Keputusan Menteri Kesehatan Republik Indonesia Nomor: 1995/MENKES/SK/XII/2010.',
      icon: Icons.child_care,
    ),
    DataSourceItem(
      id: 'source_diet_pasien',
      title: 'Penatalaksanaan Diet Pada Pasien',
      description:
          'Penulis : Retno Wahyuningsih, S.Gz.\nEdisi Pertama - Yogyakarta; Graha Ilmu, 2013\nxiv + 244 halaman, 1 jilid : 26 cm\nISBN: 978-602-262-065-5',
      icon: Icons.book,
    ),
    DataSourceItem(
      id: 'source_penuntun_diet',
      title: 'Penuntun Diet dan Terapi Gizi',
      description:
          'Penulis : Persatuan Ahli Gizi Indonesia & Asosiasi Dietisen indonesia\nEdisi Kelima - Jakarta; EGC, 2025\nxxiii + 520 halaman : ilustrasi; 15,5 cm x 24 cm\nISBN: 978-623-203-625-3',
      icon: Icons.book,
    ),
    DataSourceItem(
      id: 'source_perkeni',
      title: 'Pedoman Pengelolaan Diabetes Melitus Tipe 2 (2024)',
      description:
          'Penulis: Perkumpulan Endokrinologi Indonesia (PERKENI)\nTahun: 2024\nDiterbitkan oleh: PB PERKENI',
      icon: Icons.local_library,
    ),
  ];

  // Data Tabel Referensi
  static const List<ReferenceTableItem> referenceTables = [
    ReferenceTableItem(
      id: 'table_activity',
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
    ReferenceTableItem(
      id: 'table_stress',
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
    ReferenceTableItem(
      id: 'table_imt_indo',
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
     ReferenceTableItem(
      id: 'table_imt_asia',
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
    ReferenceTableItem(
      id: 'table_imt_eropa',
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
  ];
  static final List<FormulaItem> formulas = [
    FormulaItem(
      id: 'formula_ginjal',
      title: 'Kebutuhan Protein (Ginjal Kronik)',
      formulaName: 'Rumus Perhitungan (Berdasarkan BBI)',
      formulaContent: Column(
        children: [
          const Text(
            'Pasien Pradialisis (Belum HD)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          _buildColoredFormulaBox('Total Protein = (0,6 s/d 0,8) x BBI', Colors.orange),
          const SizedBox(height: 12),
          const Text(
            'Pasien Hemodialisis (HD Rutin)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          _buildColoredFormulaBox('Total Protein = (1,2) x BBI', Colors.red),
        ],
      ),
      note: 'Keterangan:\n'
          ' BBI = Berat Badan Ideal (dihitung dengan rumus Broca).\n'
          ' Rumus ini memastikan ginjal tidak bekerja terlalu berat akibat kelebihan protein dari berat badan aktual (jika pasien obesitas/edema).\n'
          ' Min. 50% protein harus bernilai biologis tinggi (telur, daging, ikan).',
    ),
    const FormulaItem(
      id: 'formula_perkeni',
      title: 'Kebutuhan Kalori Diet DM',
      formulaName: 'Metode PERKENI 2024',
      formulaContent: Text(
        'Total = (BBI x Kalori Basal) + Aktivitas - Usia +/- Koreksi BB +/- Stress Metabolik',
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
      ),
      note: 'Sumber: Pedoman Pengelolaan dan Pencegahan Diabetes Melitus Tipe 2 Dewasa di Indonesia 2024, Hal. 53-54.\n\n'
          'Rincian Faktor:\n'
          ' Kalori Basal: Pria (30 kal/kg BBI), Wanita (25 kal/kg BBI)\n'
          ' Koreksi Usia: 40-59 th (-5%), 60-69 th (-10%), >70 th (-20%)\n'
          ' Aktivitas: Ringan (+20%), Sedang (+30%), Berat (+40%)\n'
          ' Status Gizi: Gemuk (-20% s/d -30%), Kurus (+20% s/d +30%)',
    ),
    const FormulaItem(
      id: 'formula_broca',
      title: 'Berat Badan Ideal (BBI)',
      formulaName: 'Rumus Broca (Modifikasi)',
      formulaContent: Text(
        '(a) (Tinggi Badan (cm) - 100) - 10%) \n(b) (Tinggi Badan (cm) - 100)',
        style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
      ),
      note: 'Pada persamaan (a) digunakan Bagi pria dengan tinggi badan ≥ 160 cm dan wanita dengan tinggi badan ≥ 150 cm. sedangkan Bagi pria dengan tinggi badan < 160 cm dan wanita dengan tinggi badan < 150 cm menggunakan persamaan (b)',
    ),
    const FormulaItem(
      id: 'formula_bbi_anak',
      title: 'Berat Badan Ideal (Anak)',
      formulaName: 'Usia < 12 tahun',
      formulaContent: Text(
        '0 - 11 bulan: \nDBW = a + 9 / 2 atau a/2 + 3 s/d 4\n\n1 - 6 tahun: \nBBI = 2n + 8\n\n7 - 12 tahun: \nBBI = 7n-5/2',
        style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
      ),
      note: 'a = usia dalam bulan\nn = usia dalam tahun',
    ),
    const FormulaItem(
      id: 'formula_imt',
      title: 'Indeks Massa Tubuh (IMT)',
      formulaName: 'Standar WHO / Kemenkes',
      formulaContent: FractionText('Berat Badan (kg)', 'Tinggi Badan (m) x Tinggi Badan (m)'),
      note: 'Kategori: Kurus (<18.5), Normal (18.5-25.0), Gemuk (>25.0).',
    ),
    const FormulaItem(
      id: 'formula_bmr',
      title: 'Basal Metabolic Rate (BMR)',
      formulaName: 'Kebutuhan Energi Basal',
      formulaContent: Text(
        'Persamaan Harris-Benedict :\n'
        'Pria: 66,47+(13,75 x BB)+(5,003 x TB)-(6,755 x U)\n\n'
        'Wanita: 655,1+(9,563 x BB)+(1,850 x TB)-(4,676xU)\n\n'
        'Persamaan Mifflin-St Jeor :\n'
        'Pria: 5+(9,99 x BB)+(6,25 x TB)-(4,92 x U)\n\n'
        'Wanita: 161-(9,99 x BB)+(6,25 x TB)-(4,92 x U)',
        style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 10.5),
      ),
      note: 'BB = Berat Badan (kg)\nTB = Tinggi Badan (cm)\nU = Usia (Tahun)',
    ),
    const FormulaItem(
      id: 'formula_tdee',
      title: 'Total Daily Energy Expenditure (TDEE)',
      formulaName: 'Faktor Aktivitas Fisik',
      formulaContent: Text(
        'BMR x Faktor Aktivitas x Faktor Stress',
        style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
      ),
      note: 'TDEE adalah perkiraan jumlah total kalori yang dibakar oleh tubuh dalam satu hari (24 jam).',
    ),
    const FormulaItem(
      id: 'formula_makronutrien',
      title: 'Kebutuhan Makronutrien Umum',
      formulaName: 'Persentase dari Total Kalori (TDEE)',
      formulaContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ' Protein (15%) = (15% x TDEE) / 4',
            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            ' Lemak (25%) = (25% x TDEE) / 9',
            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            ' Karbohidrat (60%) = (60% x TDEE) / 4',
            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
          ),
        ],
      ),
      note: 'Keterangan Nilai Konversi Kalori:\n'
          ' 1 gram Protein = 4 kkal\n'
          ' 1 gram Lemak = 9 kkal\n'
          ' 1 gram Karbohidrat = 4 kkal\n\n'
          '*Catatan: Persentase di atas adalah pedoman gizi seimbang secara umum. Distribusi makronutrien dapat diubah menyesuaikan kondisi klinis dan jenis diet pasien (misalnya: diet DM, diet ginjal, atau diet rendah lemak).',
    ),
    // --- TAMBAHAN FORMULA GIZI ANAK ---
    const FormulaItem(
      id: 'formula_energi_protein_anak',
      title: 'Kebutuhan Energi & Protein (Anak)',
      formulaName: 'Berdasarkan AKG (Per kg Berat Badan)',
      formulaContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ' < 6 bln   : E=108 kkal/kg, P=2.2 g/kg\n'
            ' 6-11 bln  : E=98 kkal/kg, P=1.5 g/kg\n'
            ' 1-3 thn   : E=102 kkal/kg, P=1.23 g/kg\n'
            ' 4-6 thn   : E=90 kkal/kg, P=1.2 g/kg\n'
            ' 7-10 thn  : E=70 kkal/kg, P=1.0 g/kg\n'
            ' 11-14 thn : (L: 55 kkal, P: 47 kkal), P=1.0 g/kg\n'
            ' > 14 thn  : (L: 45 kkal, P: 40 kkal), P=0.8 g/kg',
            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
      note: 'Catatan:\n'
          'E = Energi (Kkal), P = Protein (Gram). '
          'Perhitungan menggunakan Berat Badan Ideal (BBI) jika tersedia, '
          'atau menggunakan berat badan aktual untuk target tumbuh kejar (catch-up growth).',
    ),

    const FormulaItem(
      id: 'formula_makro_anak',
      title: 'Kebutuhan Makronutrien (Anak)',
      formulaName: 'Distribusi Lemak dan Karbohidrat',
      formulaContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Energi = Kalori/kg x Berat Badan',
            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
          ),
          SizedBox(height: 8),
          Text(
            'Protein = Protein/kg x Berat Badan',
            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
          ),
          SizedBox(height: 8),
          Text(
            'Lemak (35%) = (35% x Total Energi) / 9',
            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
          ),
          SizedBox(height: 8),
          Text(
            'Karbohidrat = (Total Energi - (Protein x 4) - (Lemak x 9)) / 4',
            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
      note: 'Keterangan:\n'
          'Rentang kebutuhan lemak anak umumnya 30-40% untuk usia 1-3 tahun dan 25-35% untuk 4-18 tahun. '
          'Aplikasi ini menggunakan nilai rata-rata 35%. Karbohidrat dihitung dari sisa total energi setelah dikurangi kalori dari protein dan lemak.',
    ),

    const FormulaItem(
      id: 'formula_cairan_anak',
      title: 'Kebutuhan Cairan Anak',
      formulaName: 'Rumus Holliday-Segar',
      formulaContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ' 1 - 10 kg  : 100 ml / kg BB',
            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
          ),
          SizedBox(height: 8),
          Text(
            ' 11 - 20 kg : 1000 ml + 50 ml',
            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
          ),
          SizedBox(height: 8),
          Text(
            ' > 20 kg    : 1500 ml + 20 ml',
            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
      note: 'Keterangan:\n'
          'Rumus ini digunakan untuk menghitung kebutuhan cairan pemeliharaan harian (maintenance fluid) pada anak berdasarkan berat badannya.',
    ),
    const FormulaItem(
      id: 'formula_zscore_anak',
      title: 'Perhitungan Z-Score (Status Gizi Anak)',
      formulaName: 'Simpangan Baku (Standard Deviation)',
      formulaContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. Jika Nilai Riil < Nilai Median:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Center(
            child: FractionText(
              'Nilai Riil - Nilai Median',
              'Median - SD Minus Satu (-1 SD)',
            ),
          ),
          SizedBox(height: 12),
          Text(
            '2. Jika Nilai Riil > Nilai Median:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Center(
            child: FractionText(
              'Nilai Riil - Nilai Median',
              'SD Plus Satu (+1 SD) - Median',
            ),
          ),
        ],
      ),
      note: 'Keterangan:\n'
          ' Nilai Riil: Hasil pengukuran (BB, TB, atau IMT) pasien.\n'
          ' Median & SD: Nilai standar WHO sesuai jenis kelamin dan umur pasien.\n'
          ' Indikator yang dihitung meliputi: BB/U (Berat Badan menurut Umur), TB/U (Tinggi Badan menurut Umur), BB/TB (Berat Badan menurut Tinggi Badan), dan IMT/U (Indeks Massa Tubuh menurut Umur).',
    ),
    const FormulaItem(
      id: 'formula_schofield_anak',
      title: 'Basal Metabolic Rate (BMR) Anak',
      formulaName: 'Formula Schofield (0 - 18 Tahun)',
      formulaContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Laki-laki (Berdasarkan Berat Badan):\n'
            ' < 3 thn   : (59.512 x W) - 30.4\n'
            ' 3-10 thn  : (22.7 x W) + 504.3\n'
            ' 10-18 thn : (17.5 x W) + 651\n\n'
            'Perempuan (Berdasarkan Berat Badan):\n'
            ' < 3 thn   : (58.317 x W) - 31.1\n'
            ' 3-10 thn  : (22.706 x W) + 485.9\n'
            ' 10-18 thn : (13.384 x W) + 692.6\n\n'
            'Laki-laki (Berat & Tinggi Badan):\n'
            ' < 3 thn   : (0.167 x W) + (1517.4 x H) - 616.6\n'
            ' 3-10 thn  : (19.59 x W) + (130.3 x H) + 414.9\n'
            ' 10-18 thn : (16.25 x W) + (137.2 x H) + 515.5\n\n'
            'Perempuan (Berat & Tinggi Badan):\n'
            ' < 3 thn   : (16.252 x W) + (1023.3 x H) - 413.5\n'
            ' 3-10 thn  : (16.969 x W) + (161.8 x H) + 371.2\n'
            ' 10-18 thn : (8.365 x W) + (465 x H) + 200.0',
            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
      note: 'Keterangan:\n'
          'W = Berat Badan dalam Kilogram (kg)\n'
          'H = Tinggi Badan dalam Meter (m)\n'
          'Formula Schofield direkomendasikan secara internasional (termasuk oleh WHO/FAO/UNU) '
          'untuk memperkirakan angka metabolisme basal (BMR) pada anak-anak dan remaja.',
    ),
  ];

  // Helper Widget Pindah Kesini
  static Widget _buildColoredFormulaBox(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
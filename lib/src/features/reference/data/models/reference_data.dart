import 'package:flutter/material.dart';

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
}
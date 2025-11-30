// lib/src/features/disease_calculation/data/nutrition_reference_data.dart

class NutritionReferenceItem {
  final String code;
  final String label;
  final String? definition; // Opsional, untuk detail

  const NutritionReferenceItem({
    required this.code,
    required this.label,
    this.definition,
  });
}

class NutritionKnowledgeBase {
  // --- DIAGNOSIS (Masalah) ---
  // Diambil dari terminologi dan kode diagnosis gizi - sheet 1.csv
  static const List<NutritionReferenceItem> diagnoses = [
    // Domain Klinis (NC)
    NutritionReferenceItem(
      code: 'NC-2.2',
      label: 'Perubahan nilai laboratorium terkait gizi',
      definition: 'Kadar glukosa/HbA1c/Lipid di atas nilai normal',
    ),
    NutritionReferenceItem(
      code: 'NC-3.1',
      label: 'Berat badan kurang',
      definition: 'IMT < 18.5 kg/m²',
    ),
    NutritionReferenceItem(
      code: 'NC-3.3',
      label: 'Kelebihan berat badan/Obesitas',
      definition: 'IMT ≥ 23 kg/m² (Asia Pasifik) atau ≥ 25 kg/m²',
    ),
    
    // Domain Asupan (NI) - Fokus Diabetes
    NutritionReferenceItem(
      code: 'NI-5.8.3',
      label: 'Asupan karbohidrat berlebih',
      definition: 'Konsumsi karbohidrat sederhana/manis berlebihan',
    ),
    NutritionReferenceItem(
      code: 'NI-5.4',
      label: 'Penurunan kebutuhan zat gizi (spesifik)',
      definition: 'Perlu pembatasan protein (Ginjal) atau Natrium (Hipertensi)',
    ),
    
    // Domain Perilaku (NB)
    NutritionReferenceItem(
      code: 'NB-1.5',
      label: 'Gangguan pola makan',
      definition: 'Jadwal makan tidak teratur',
    ),
    NutritionReferenceItem(
      code: 'NB-1.7',
      label: 'Pemilihan makanan yang salah',
      definition: 'Kurang pengetahuan terkait makanan indeks glikemik tinggi',
    ),
  ];

  // --- INTERVENSI (Perencanaan) ---
  // Diambil dari intervensi gizi - sheet 1.csv
  static const List<NutritionReferenceItem> interventions = [
    NutritionReferenceItem(
      code: 'ND-1.1',
      label: 'Diet Makanan Biasa/Sehat',
      definition: 'Gizi seimbang sesuai prinsip 3J',
    ),
    NutritionReferenceItem(
      code: 'ND-1.2',
      label: 'Modifikasi distribusi/jenis/jumlah makanan',
      definition: 'Diet Rendah Kalori / Diet DM / Diet Rendah Garam',
    ),
    NutritionReferenceItem(
      code: 'E-1.1',
      label: 'Edukasi Konten Materi Gizi',
      definition: 'Edukasi tentang karbohidrat, indeks glikemik, dan label makanan',
    ),
    NutritionReferenceItem(
      code: 'RC-1.4',
      label: 'Kolaborasi asuhan aktivitas fisik',
      definition: 'Rekomendasi olahraga aerobik 150 menit/minggu',
    ),
  ];

  // --- MONITORING & EVALUASI ---
  // Diambil dari monitoring dan evaluasi gizi - sheet 1.csv
  static const List<NutritionReferenceItem> monitoring = [
    NutritionReferenceItem(
      code: 'S-1.1',
      label: 'Antropometri (BB & IMT)',
      definition: 'Monitoring perubahan berat badan per bulan',
    ),
    NutritionReferenceItem(
      code: 'S-2.5',
      label: 'Profil Glukosa (GDS/GDP/HbA1c)',
      definition: 'Target GDP 80-130 mg/dL, HbA1c < 7%',
    ),
    NutritionReferenceItem(
      code: 'FH-1.1.1',
      label: 'Asupan Energi Total',
      definition: 'Kepatuhan terhadap rencana diet',
    ),
    NutritionReferenceItem(
      code: 'S-2.2',
      label: 'Profil Lipid',
      definition: 'Jika ada dislipidemia',
    ),
  ];
}
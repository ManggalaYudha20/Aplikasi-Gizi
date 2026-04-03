// lib\src\features\diabetes_calculation\data\models\diabetes_knowledge_base.dart

/// Model untuk Aturan Universal Penyakit (Batasan dan Pantangan)
class DiseaseGuideline {
  final String diseaseId;
  final String diseaseName;
  final List<String> forbiddenFoods;
  final Map<String, List<String>> conditionalForbiddenFoods;

  DiseaseGuideline({
    required this.diseaseId,
    required this.diseaseName,
    required this.forbiddenFoods,
    this.conditionalForbiddenFoods = const {},
  });
}
class MealItemRule {
  final String categoryLabel;
  final dynamic portion;
  final double? weightGrams; // Tambahan baru
  final String? urt;

  MealItemRule({
    required this.categoryLabel,
    required this.portion,
    this.weightGrams,
    this.urt,
  });
}

/// Model untuk Aturan Distribusi Porsi (Berdasarkan Target Kalori)
class DietDistributionRule {
  final double targetCalories;
  final Map<String, List<MealItemRule>> distribution;

  DietDistributionRule({
    required this.targetCalories,
    required this.distribution,
  });
}
// ============================================================================
// DATA STATIS KNOWLEDGE BASE : DIABETES MELITUS
// ============================================================================

/// Fakta Aturan Universal Diabetes Melitus
/// Disusun berdasarkan Dokumen Pedoman Nutrisi DM dan Filter TKPI CSV
final DiseaseGuideline diabetesGuideline = DiseaseGuideline(
  diseaseId: 'dm',
  diseaseName: 'Diabetes Melitus',
  // Diambil dari makanan dengan status "Tidak Dianjurkan" pada CSV TKPI serta Pedoman DM
  forbiddenFoods: [
    // Gula Sederhana, Manisan, & Makanan/Minuman Berpengawet Gula
    'gula pasir', 'gula jawa', 'sirup', 'jam', 'jeli', 'kental manis', 
    'minuman botol', 'es krim', 'kue manis', 'dodol', 'cake', 'tarcis', 'manisan',
    // Lemak Tinggi (Jenuh/Trans) & Makanan Cepat Saji
    'fast food', 'goreng', // Menangkap bihun goreng, getuk goreng, kacang goreng, dll.
    'kerupuk', 'emping tebal goreng',
    // Natrium Tinggi / Diawetkan
    'ikan asin', 'telor asin', 'diawetkan', 'kaleng',
    // Kue Tradisional Berisiko Tinggi (Berdasarkan list CSV Tidak Dianjurkan)
    'apem', 'bakpia', 'bagea', 'kelepon', 'kue ali', 'kue lumpur', 'kue pelita', 'kue sus',
    // Kuah Lemak Jenuh / Santan Kental Tinggi
    'gulai',
    //non-halal
    'babi'
  ],
);

/// Fakta Aturan Distribusi Menu (Satuan Penukar) untuk DM
/// Disalin persis berdasarkan Tabel 2.3 Pembagian Makanan Sehari Standar Diet DM
final _dietDM1100Rule = DietDistributionRule(
  targetCalories: 1100.0,
  distribution: {
    'Makan Pagi (07.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Roti/Serealia)', portion: 0.5),
      MealItemRule(categoryLabel: 'Protein Hewani (Ikan/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 'S'),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 1.0),
    ],
    'Selingan Pagi (10.00)': [
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
    ],
    'Makan Siang (13.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Umbi)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Hewani (Daging/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 1.0), // Mewakili Sayuran B
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 1.0),
    ],
    'Selingan Sore (16.00)': [
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
    ],
    'Makan Malam (19.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Umbi)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Hewani (Ikan/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 1.0),
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 1.0),
    ],
  },
);

// --- Diet DM II (1300 Kkal) ---
final _dietDM1300Rule = DietDistributionRule(
  targetCalories: 1300.0,
  distribution: {
    'Makan Pagi (07.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Roti/Serealia)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Hewani (Ikan/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 'S'),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 1.0),
    ],
    'Selingan Pagi (10.00)': [
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
    ],
    'Makan Siang (13.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Umbi)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Hewani (Daging/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 1.0),
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 2.0),
    ],
    'Selingan Sore (16.00)': [
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
    ],
    'Makan Malam (19.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Umbi)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Hewani (Ikan/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 1.0),
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 1.0),
    ],
  },
);

// --- Diet DM III (1500 Kkal) ---
final _dietDM1500Rule = DietDistributionRule(
  targetCalories: 1500.0,
  distribution: {
    'Makan Pagi (07.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Roti/Serealia)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Hewani (Ikan/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 0.5),
      MealItemRule(categoryLabel: 'Sayuran', portion: 'S'),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 1.0),
    ],
    'Selingan Pagi (10.00)': [
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
    ],
    'Makan Siang (13.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Umbi)', portion: 2.0),
      MealItemRule(categoryLabel: 'Protein Hewani (Daging/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 1.0),
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 2.0),
    ],
    'Selingan Sore (16.00)': [
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
    ],
    'Makan Malam (19.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Umbi)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Hewani (Ikan/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 1.0),
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 1.0),
    ],
  },
);

// --- Diet DM IV (1700 Kkal) ---
final _dietDM1700Rule = DietDistributionRule(
  targetCalories: 1700.0,
  distribution: {
    'Makan Pagi (07.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Roti/Serealia)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Hewani (Ikan/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 0.5),
      MealItemRule(categoryLabel: 'Sayuran', portion: 'S'),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 1.0),
    ],
    'Selingan Pagi (10.00)': [
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
    ],
    'Makan Siang (13.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Umbi)', portion: 2.0),
      MealItemRule(categoryLabel: 'Protein Hewani (Daging/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 1.0),
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 2.0),
    ],
    'Selingan Sore (16.00)': [
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
    ],
    'Makan Malam (19.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Umbi)', portion: 2.0),
      MealItemRule(categoryLabel: 'Protein Hewani (Ikan/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 1.0),
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 1.0),
    ],
  },
);

// --- Diet DM V (1900 Kkal) ---
final _dietDM1900Rule = DietDistributionRule(
  targetCalories: 1900.0,
  distribution: {
    'Makan Pagi (07.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Roti/Serealia)', portion: 1.5),
      MealItemRule(categoryLabel: 'Protein Hewani (Ikan/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 'S'),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 2.0),
    ],
    'Selingan Pagi (10.00)': [
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
    ],
    'Makan Siang (13.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Umbi)', portion: 2.0),
      MealItemRule(categoryLabel: 'Protein Hewani (Daging/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 1.0),
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 2.0),
    ],
    'Selingan Sore (16.00)': [
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
    ],
    'Makan Malam (19.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Umbi)', portion: 2.0),
      MealItemRule(categoryLabel: 'Protein Hewani (Ikan/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 1.0),
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 2.0),
    ],
  },
);

// --- Diet DM VI (2100 Kkal) ---
final _dietDM2100Rule = DietDistributionRule(
  targetCalories: 2100.0,
  distribution: {
    'Makan Pagi (07.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Roti/Serealia)', portion: 1.5),
      MealItemRule(categoryLabel: 'Protein Hewani (Ikan/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 'S'),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 2.0),
    ],
    'Selingan Pagi (10.00)': [
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
    ],
    'Makan Siang (13.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Umbi)', portion: 2.5),
      MealItemRule(categoryLabel: 'Protein Hewani (Daging/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 1.0),
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 3.0),
    ],
    'Selingan Sore (16.00)': [
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
    ],
    'Makan Malam (19.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Umbi)', portion: 2.0),
      MealItemRule(categoryLabel: 'Protein Hewani (Ikan/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 1.0),
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 2.0),
    ],
  },
);

// --- Diet DM VII (2300 Kkal) ---
final _dietDM2300Rule = DietDistributionRule(
  targetCalories: 2300.0,
  distribution: {
    'Makan Pagi (07.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Roti/Serealia)', portion: 1.5),
      MealItemRule(categoryLabel: 'Protein Hewani (Ikan/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 'S'),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 2.0),
    ],
    'Selingan Pagi (10.00)': [
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
      MealItemRule(categoryLabel: 'Susu', portion: 1.0),
    ],
    'Makan Siang (13.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Umbi)', portion: 3.0),
      MealItemRule(categoryLabel: 'Protein Hewani (Daging/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 1.0),
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 3.0),
    ],
    'Selingan Sore (16.00)': [
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
    ],
    'Makan Malam (19.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Umbi)', portion: 2.5),
      MealItemRule(categoryLabel: 'Protein Hewani (Ikan/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 1.0),
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 2.0),
    ],
  },
);

// --- Diet DM VIII (2500 Kkal) ---
final _dietDM2500Rule = DietDistributionRule(
  targetCalories: 2500.0,
  distribution: {
    'Makan Pagi (07.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Roti/Serealia)', portion: 2.0),
      MealItemRule(categoryLabel: 'Protein Hewani (Ikan/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 1.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 'S'),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 2.0),
    ],
    'Selingan Pagi (10.00)': [
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
      MealItemRule(categoryLabel: 'Susu', portion: 1.0),
    ],
    'Makan Siang (13.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Umbi)', portion: 3.0),
      MealItemRule(categoryLabel: 'Protein Hewani (Daging/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 2.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 1.0),
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 3.0),
    ],
    'Selingan Sore (16.00)': [
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
    ],
    'Makan Malam (19.00)': [
      MealItemRule(categoryLabel: 'Karbohidrat (Nasi/Umbi)', portion: 2.5),
      MealItemRule(categoryLabel: 'Protein Hewani (Ikan/Ayam/Telur)', portion: 1.0),
      MealItemRule(categoryLabel: 'Protein Nabati (Tempe/Tahu)', portion: 2.0),
      MealItemRule(categoryLabel: 'Sayuran', portion: 1.0),
      MealItemRule(categoryLabel: 'Buah', portion: 1.0),
      MealItemRule(categoryLabel: 'Minyak/Lemak', portion: 2.0),
    ],
  },
);

// ============================================================================
// 3. DAFTAR KUMPULAN RULE UNTUK MESIN INFERENSI
// ============================================================================
final List<DietDistributionRule> diabetesDistributionRules = [
  _dietDM1100Rule,
  _dietDM1300Rule,
  _dietDM1500Rule,
  _dietDM1700Rule,
  _dietDM1900Rule,
  _dietDM2100Rule,
  _dietDM2300Rule,
  _dietDM2500Rule,
];
// lib/src/features/kidney_calculation/data/models/kidney_knowledge_base.dart

import 'package:aplikasi_diagnosa_gizi/src/features/expert_system/data/models/knowledge_base_model.dart'; // Import model DiseaseGuideline & DietDistributionRule

// 1. Aturan Universal Ginjal (Contoh pantangan umum)
final DiseaseGuideline kidneyGuideline = DiseaseGuideline(
  diseaseId: 'ginjal',
  diseaseName: 'Penyakit Ginjal Kronis (Pre-dialisis & Hemodialisis)',
  forbiddenFoods: [
    // Pantangan umum ginjal
    'ikan asin', 'santan', 'kelapa', 'minyak kelapa', 'mentega biasa', 
    'margarin biasa', 'ayam dengan kulit',
    // Pantangan nabati (Kacang-kacangan sering dibatasi ketat)
    'kacang tanah', 'kacang merah', 'kacang hijau',
    // Tinggi Kalium (Dihindari jika hiperkalemia)
    'bayam', 'daun singkong', 'asparagus', 'kembang kol', 'kangkung',
    'pisang', 'belimbing', 'bit', 'alpukat', 'mangga', 'semangka', 'melon',
    'kentang', 'havermut', 'singkong', 'ubi',

    //non-halal
    'babi'
  ],
  conditionalForbiddenFoods: {
  'hiperkalemia': [ 
    // Sayuran tinggi kalium
    'bayam', 'daun singkong', 'asparagus', 'kembang kol', 'kangkung', 'bit',
    'daun pepaya', 'daun melinjo', 'genjer', 'jamur kuping', 'tomat',
    
    // Buah-buahan tinggi kalium
    'pisang', 'belimbing', 'alpukat', 'mangga', 'semangka', 'melon', 'nangka',
    
    // Umbi-umbian tinggi kalium
    'kentang', 'talas', 'ubi jalar', 'gadung',
    
    // Kacang-kacangan tinggi kalium
    'kacang kedelai', 'kacang merah', 'kacang hijau', 'kacang tanah'
  ]
}
);
final List<String> allowedProteinSourcesPreDialisis = [
  'telur', 'ikan', 'ayam', 'daging sapi' 
];

final List<String> allowedVegetableSources = [
  'tahu', 'tempe', 'kacang hijau' 
];
// 2. Aturan Distribusi berdasarkan Target PROTEIN (bukan kalori)
// Catatan: Gunakan field targetCalories pada model bawaan untuk mewakili target protein 
// atau modifikasi model DietDistributionRule untuk menerima parameter fleksibel.
final List<DietDistributionRule> kidneyDistributionRules = [
  DietDistributionRule(
    targetCalories: 30.0, 
    distribution: {
      'Makan Pagi (06.00 - 08.00)': [
        MealItemRule(categoryLabel: 'Pokok', portion: 0.6, weightGrams: 30.0, urt: '½ gls nasi'),
        MealItemRule(categoryLabel: 'Lauk Hewani', portion: 1.0, weightGrams: 50.0, urt: '1 btr'),
        MealItemRule(categoryLabel: 'Lemak', portion: 2.0, weightGrams: 10.0, urt: '1 sdm'),
        MealItemRule(categoryLabel: 'Pemanis', portion: 1.0, weightGrams: 10.0, urt: '1 sdm'),
      ],
      'Selingan Pagi (10.00)': [
        MealItemRule(categoryLabel: 'Snack', portion: 1.0, weightGrams: 75.0, urt: '1 porsi'),
        MealItemRule(categoryLabel: 'Pemanis', portion: 1.0, weightGrams: 10.0, urt: '1 sdm'),
      ],
      'Makan Siang (12.00 - 13.00)': [
        MealItemRule(categoryLabel: 'Pokok', portion: 0.8, weightGrams: 40.0, urt: '½ gls nasi'),
        MealItemRule(categoryLabel: 'Lauk Hewani', portion: 0.8, weightGrams: 40.0, urt: '1 ptg sdg'),
        MealItemRule(categoryLabel: 'Sayuran', portion: 0.5, weightGrams: 50.0, urt: '½ gls'),
        MealItemRule(categoryLabel: 'Buah', portion: 1.0, weightGrams: 75.0, urt: '1 bh sdg'),
        MealItemRule(categoryLabel: 'Lemak', portion: 3.0, weightGrams: 15.0, urt: '1½ sdm'),
      ],
      'Selingan Sore (16.00)': [
        MealItemRule(categoryLabel: 'Snack', portion: 1.0, weightGrams: 75.0, urt: '1 porsi'),
      ],
      'Makan Malam (18.00 - 19.00)': [
        MealItemRule(categoryLabel: 'Pokok', portion: 0.6, weightGrams: 30.0, urt: '½ gls nasi'),
        MealItemRule(categoryLabel: 'Sayuran', portion: 0.5, weightGrams: 50.0, urt: '½ gls'),
        MealItemRule(categoryLabel: 'Buah', portion: 1.0, weightGrams: 75.0, urt: '1 ptg sdg'),
        MealItemRule(categoryLabel: 'Lemak', portion: 3.0, weightGrams: 15.0, urt: '1½ sdm'),
      ],
    },
  ),

  DietDistributionRule(
    targetCalories: 40.0,
    distribution: {
      'Makan Pagi (06.00 - 08.00)': [
        MealItemRule(categoryLabel: 'Pokok', portion: 1.0, weightGrams: 50.0, urt: '¾ gls nasi'),
        MealItemRule(categoryLabel: 'Lauk Hewani', portion: 1.0, weightGrams: 50.0, urt: '1 btr'),
        MealItemRule(categoryLabel: 'Sayuran', portion: 0.5, weightGrams: 50.0, urt: '½ gls'),
        MealItemRule(categoryLabel: 'Lemak', portion: 2.0, weightGrams: 10.0, urt: '1 sdm'),
        MealItemRule(categoryLabel: 'Pemanis', portion: 2.0, weightGrams: 20.0, urt: '1½ sdm'),
      ],
      'Selingan Pagi (10.00)': [
        MealItemRule(categoryLabel: 'Snack', portion: 1.0, weightGrams: 50.0, urt: '1 porsi'),
        MealItemRule(categoryLabel: 'Pemanis', portion: 2.0, weightGrams: 20.0, urt: '2 sdm'),
      ],
      'Makan Siang (12.00 - 13.00)': [
        MealItemRule(categoryLabel: 'Pokok', portion: 1.0, weightGrams: 50.0, urt: '¾ gls nasi'),
        MealItemRule(categoryLabel: 'Lauk Hewani', portion: 0.8, weightGrams: 40.0, urt: '1 ptg sdg'),
        MealItemRule(categoryLabel: 'Lauk Nabati', portion: 0.5, weightGrams: 25.0, urt: '1 ptg sdg'),
        MealItemRule(categoryLabel: 'Sayuran', portion: 0.5, weightGrams: 50.0, urt: '½ gls'),
        MealItemRule(categoryLabel: 'Buah', portion: 1.0, weightGrams: 100.0, urt: '1 ptg bsr'),
        MealItemRule(categoryLabel: 'Lemak', portion: 4.0, weightGrams: 20.0, urt: '2 sdm'),
      ],
      'Selingan Sore (16.00)': [
        MealItemRule(categoryLabel: 'Snack', portion: 1.0, weightGrams: 50.0, urt: '1 porsi'),
      ],
      'Makan Malam (18.00 - 19.00)': [
        MealItemRule(categoryLabel: 'Pokok', portion: 1.0, weightGrams: 50.0, urt: '¾ gls nasi'),
        MealItemRule(categoryLabel: 'Lauk Hewani', portion: 0.8, weightGrams: 40.0, urt: '1 ptg sdg'),
        MealItemRule(categoryLabel: 'Sayuran', portion: 0.5, weightGrams: 50.0, urt: '½ gls'),
        MealItemRule(categoryLabel: 'Buah', portion: 0.5, weightGrams: 50.0, urt: '1 ptg sdg'),
        MealItemRule(categoryLabel: 'Lemak', portion: 2.0, weightGrams: 10.0, urt: '1 sdm'),
      ],
    },
  ),

  DietDistributionRule(
    targetCalories: 50.0,
    distribution: {
      'Makan Pagi (06.00 - 08.00)': [
        MealItemRule(categoryLabel: 'Pokok', portion: 1.0, weightGrams: 50.0, urt: '¾ gls nasi'),
        MealItemRule(categoryLabel: 'Lauk Hewani', portion: 1.0, weightGrams: 50.0, urt: '1 btr'),
        MealItemRule(categoryLabel: 'Sayuran', portion: 0.5, weightGrams: 50.0, urt: '½ gls'),
        MealItemRule(categoryLabel: 'Lemak', portion: 2.0, weightGrams: 10.0, urt: '1 sdm'),
      ],
      'Selingan Pagi (10.00)': [
        MealItemRule(categoryLabel: 'Snack', portion: 1.0, weightGrams: 15.0, urt: '3 sdm'), 
        MealItemRule(categoryLabel: 'Pemanis', portion: 2.0, weightGrams: 20.0, urt: '2 sdm'),
      ],
      'Makan Siang (12.00 - 13.00)': [
        MealItemRule(categoryLabel: 'Pokok', portion: 1.5, weightGrams: 75.0, urt: '1 gls nasi'),
        MealItemRule(categoryLabel: 'Lauk Hewani', portion: 1.0, weightGrams: 50.0, urt: '1 ptg sdg'),
        MealItemRule(categoryLabel: 'Lauk Nabati', portion: 1.0, weightGrams: 50.0, urt: '1 bj sdg'),
        MealItemRule(categoryLabel: 'Sayuran', portion: 0.75, weightGrams: 75.0, urt: '¾ gls'),
        MealItemRule(categoryLabel: 'Buah', portion: 1.0, weightGrams: 100.0, urt: '1 ptg bsr'),
        MealItemRule(categoryLabel: 'Lemak', portion: 3.0, weightGrams: 15.0, urt: '1½ sdm'),
      ],
      'Selingan Sore (16.00)': [
        MealItemRule(categoryLabel: 'Snack', portion: 1.0, weightGrams: 50.0, urt: '1 porsi'),
      ],
      'Makan Malam (18.00 - 19.00)': [
        MealItemRule(categoryLabel: 'Pokok', portion: 1.0, weightGrams: 50.0, urt: '¾ gls nasi'),
        MealItemRule(categoryLabel: 'Lauk Hewani', portion: 0.8, weightGrams: 40.0, urt: '1 ptg sdg'),
        MealItemRule(categoryLabel: 'Sayuran', portion: 0.75, weightGrams: 75.0, urt: '¾ gls'),
        MealItemRule(categoryLabel: 'Buah', portion: 1.0, weightGrams: 100.0, urt: '1 bh sdg'),
        MealItemRule(categoryLabel: 'Lemak', portion: 2.0, weightGrams: 10.0, urt: '1 sdm'),
      ],
    },
  ),

  // ── HEMODIALISIS ──

  DietDistributionRule(
    targetCalories: 60.0,
    distribution: {
      'Makan Pagi (06.00 - 08.00)': [
        MealItemRule(categoryLabel: 'Pokok', portion: 1.0, weightGrams: 50.0, urt: '¾ gls nasi'),
        MealItemRule(categoryLabel: 'Lauk Hewani', portion: 1.0, weightGrams: 50.0, urt: '1 btr'),
        MealItemRule(categoryLabel: 'Sayuran', portion: 0.5, weightGrams: 50.0, urt: '½ gls'),
        MealItemRule(categoryLabel: 'Lemak', portion: 2.0, weightGrams: 10.0, urt: '1 sdm'),
      ],
      'Selingan Pagi (10.00)': [
        MealItemRule(categoryLabel: 'Snack', portion: 1.0, weightGrams: 20.0, urt: '2 sdm'),
        MealItemRule(categoryLabel: 'Pemanis', portion: 2.0, weightGrams: 20.0, urt: '2 sdm'),
      ],
      'Makan Siang (12.00 - 13.00)': [
        MealItemRule(categoryLabel: 'Pokok', portion: 1.5, weightGrams: 75.0, urt: '1 gls nasi'),
        MealItemRule(categoryLabel: 'Lauk Hewani', portion: 1.0, weightGrams: 50.0, urt: '1 ptg sdg'),
        MealItemRule(categoryLabel: 'Lauk Nabati', portion: 1.0, weightGrams: 50.0, urt: '2 ptg sdg'),
        MealItemRule(categoryLabel: 'Sayuran', portion: 0.75, weightGrams: 75.0, urt: '¾ gls'),
        MealItemRule(categoryLabel: 'Buah', portion: 1.5, weightGrams: 150.0, urt: '1½ ptg bsr'),
        MealItemRule(categoryLabel: 'Lemak', portion: 2.0, weightGrams: 10.0, urt: '1 sdm'),
      ],
      'Selingan Sore (16.00)': [
        MealItemRule(categoryLabel: 'Susu', portion: 1.0, weightGrams: 100.0, urt: '½ gls'),
      ],
      'Makan Malam (18.00 - 19.00)': [
        MealItemRule(categoryLabel: 'Pokok', portion: 1.5, weightGrams: 75.0, urt: '1 gls nasi'),
        MealItemRule(categoryLabel: 'Lauk Hewani', portion: 1.0, weightGrams: 50.0, urt: '1 ptg sdg'),
        MealItemRule(categoryLabel: 'Lauk Nabati', portion: 1.0, weightGrams: 50.0, urt: '1 bj sdg'),
        MealItemRule(categoryLabel: 'Sayuran', portion: 0.75, weightGrams: 75.0, urt: '¾ gls'),
        MealItemRule(categoryLabel: 'Lemak', portion: 2.0, weightGrams: 10.0, urt: '1 sdm'),
      ],
    },
  ),

  DietDistributionRule(
    targetCalories: 65.0,
    distribution: {
      'Makan Pagi (06.00 - 08.00)': [
        MealItemRule(categoryLabel: 'Pokok', portion: 1.0, weightGrams: 50.0, urt: '¾ gls nasi'),
        MealItemRule(categoryLabel: 'Lauk Hewani', portion: 1.0, weightGrams: 50.0, urt: '1 btr'),
        MealItemRule(categoryLabel: 'Sayuran', portion: 0.5, weightGrams: 50.0, urt: '½ gls'),
        MealItemRule(categoryLabel: 'Lemak', portion: 2.0, weightGrams: 10.0, urt: '1 sdm'),
      ],
      'Selingan Pagi (10.00)': [
        MealItemRule(categoryLabel: 'Snack', portion: 1.0, weightGrams: 50.0, urt: '1 porsi'),
        MealItemRule(categoryLabel: 'Pemanis', portion: 2.0, weightGrams: 20.0, urt: '2 sdm'),
      ],
      'Makan Siang (12.00 - 13.00)': [
        MealItemRule(categoryLabel: 'Pokok', portion: 1.5, weightGrams: 75.0, urt: '1 gls nasi'),
        MealItemRule(categoryLabel: 'Lauk Hewani', portion: 1.0, weightGrams: 50.0, urt: '1 ptg sdg'),
        MealItemRule(categoryLabel: 'Lauk Nabati', portion: 1.0, weightGrams: 50.0, urt: '2 ptg sdg'),
        MealItemRule(categoryLabel: 'Sayuran', portion: 0.75, weightGrams: 75.0, urt: '¾ gls'),
        MealItemRule(categoryLabel: 'Buah', portion: 1.0, weightGrams: 100.0, urt: '1 bh sdg'),
        MealItemRule(categoryLabel: 'Lemak', portion: 2.0, weightGrams: 10.0, urt: '1 sdm'),
      ],
      'Selingan Sore (16.00)': [
        MealItemRule(categoryLabel: 'Susu', portion: 1.0, weightGrams: 100.0, urt: '½ gls'),
      ],
      'Makan Malam (18.00 - 19.00)': [
        MealItemRule(categoryLabel: 'Pokok', portion: 1.5, weightGrams: 75.0, urt: '1 gls nasi'),
        MealItemRule(categoryLabel: 'Lauk Hewani', portion: 1.0, weightGrams: 50.0, urt: '1 ptg sdg'),
        MealItemRule(categoryLabel: 'Lauk Nabati', portion: 1.0, weightGrams: 50.0, urt: '1 bj sdg'),
        MealItemRule(categoryLabel: 'Sayuran', portion: 0.75, weightGrams: 75.0, urt: '¾ gls'),
        MealItemRule(categoryLabel: 'Lemak', portion: 2.0, weightGrams: 10.0, urt: '1 sdm'),
      ],
    },
  ),

  DietDistributionRule(
    targetCalories: 70.0,
    distribution: {
      'Makan Pagi (06.00 - 08.00)': [
        MealItemRule(categoryLabel: 'Pokok', portion: 1.2, weightGrams: 60.0, urt: '1 gls nasi kcl'),
        MealItemRule(categoryLabel: 'Lauk Hewani', portion: 1.0, weightGrams: 50.0, urt: '1 btr'),
        MealItemRule(categoryLabel: 'Sayuran', portion: 0.5, weightGrams: 50.0, urt: '½ gls'),
        MealItemRule(categoryLabel: 'Lemak', portion: 2.0, weightGrams: 10.0, urt: '1 sdm'),
      ],
      'Selingan Pagi (10.00)': [
        MealItemRule(categoryLabel: 'Snack', portion: 1.0, weightGrams: 25.0, urt: '1 porsi'),
        MealItemRule(categoryLabel: 'Pemanis', portion: 2.0, weightGrams: 20.0, urt: '2 sdm'),
      ],
      'Makan Siang (12.00 - 13.00)': [
        MealItemRule(categoryLabel: 'Pokok', portion: 1.5, weightGrams: 75.0, urt: '1 gls nasi'),
        MealItemRule(categoryLabel: 'Lauk Hewani', portion: 1.5, weightGrams: 75.0, urt: '2 ptg sdg'),
        MealItemRule(categoryLabel: 'Lauk Nabati', portion: 1.0, weightGrams: 50.0, urt: '2 ptg sdg'),
        MealItemRule(categoryLabel: 'Sayuran', portion: 0.75, weightGrams: 75.0, urt: '¾ gls'),
        MealItemRule(categoryLabel: 'Buah', portion: 1.0, weightGrams: 100.0, urt: '1 ptg bsr'),
        MealItemRule(categoryLabel: 'Lemak', portion: 2.0, weightGrams: 10.0, urt: '1 sdm'),
      ],
      'Selingan Sore (16.00)': [
        MealItemRule(categoryLabel: 'Susu', portion: 1.0, weightGrams: 100.0, urt: '½ gls'),
      ],
      'Makan Malam (18.00 - 19.00)': [
        MealItemRule(categoryLabel: 'Pokok', portion: 1.5, weightGrams: 75.0, urt: '1 gls nasi'),
        MealItemRule(categoryLabel: 'Lauk Hewani', portion: 1.0, weightGrams: 50.0, urt: '1½ ptg sdg'),
        MealItemRule(categoryLabel: 'Lauk Nabati', portion: 1.0, weightGrams: 50.0, urt: '1 bj sdg'),
        MealItemRule(categoryLabel: 'Sayuran', portion: 0.75, weightGrams: 75.0, urt: '¾ gls'),
        MealItemRule(categoryLabel: 'Lemak', portion: 2.0, weightGrams: 10.0, urt: '1 sdm'),
      ],
    },
  ),
];
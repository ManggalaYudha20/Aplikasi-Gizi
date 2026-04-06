// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\kidney_calculation\data\models\kidney_diet_nutrition_model.dart

/// Data nilai gizi untuk satu level diet ginjal.
class KidneyDietNutrition {
  final int energi;
  final int protein;
  final int lemak;
  final int karbohidrat;
  final int kalsium;
  final double zatBesi;
  final int fosfor;
  final int vitaminA;
  final double tiamin;
  final int vitaminC;
  final int natrium;
  final int kalium;

  KidneyDietNutrition({
    required this.energi,
    required this.protein,
    required this.lemak,
    required this.karbohidrat,
    required this.kalsium,
    required this.zatBesi,
    required this.fosfor,
    required this.vitaminA,
    required this.tiamin,
    required this.vitaminC,
    required this.natrium,
    required this.kalium,
  });
}

/// Hasil kalkulasi lengkap diet ginjal untuk satu pasien.
class KidneyDietResult {
  final double idealBodyWeight;
  final double proteinNeeds;
  final double bmr;
  final int recommendedDiet;
  final bool isDialysis;
  final KidneyDietNutrition? nutritionInfo;

  KidneyDietResult({
    required this.idealBodyWeight,
    required this.proteinNeeds,
    required this.bmr,
    required this.recommendedDiet,
    required this.isDialysis,
    this.nutritionInfo,
  });
}

// ---------------------------------------------------------------------------
// Tabel data referensi nutrisi per level diet ginjal.
// Diletakkan di sini agar KidneyCalculatorService tetap murni logika.
// ---------------------------------------------------------------------------

/// Peta data nutrisi berdasarkan target protein diet (30, 35, 40, 60, 65, 70 gram).
final Map<int, KidneyDietNutrition> kidneyDietData = {
  // --- Pre-dialisis ---
  30: KidneyDietNutrition(
    energi: 1798,
    protein: 30,
    lemak: 63,
    karbohidrat: 160,
    kalsium: 190,
    kalium: 1219,
    fosfor: 452,
    natrium: 157,
    zatBesi: 4.3,
    vitaminA: 0,
    tiamin: 0,
    vitaminC: 0,
  ),
  35: KidneyDietNutrition(
    energi: 1873,
    protein: 35,
    lemak: 61,
    karbohidrat: 117,
    kalsium: 190,
    kalium: 1099,
    fosfor: 452,
    natrium: 156,
    zatBesi: 4.3,
    vitaminA: 0,
    tiamin: 0,
    vitaminC: 0,
  ),
  40: KidneyDietNutrition(
    energi: 2085,
    protein: 41,
    lemak: 63,
    karbohidrat: 161,
    kalsium: 190,
    kalium: 1219,
    fosfor: 452,
    natrium: 157,
    zatBesi: 4.3,
    vitaminA: 0,
    tiamin: 0,
    vitaminC: 0,
  ),
  // --- Hemodialisis ---
  60: KidneyDietNutrition(
    energi: 2000,
    protein: 62,
    lemak: 67,
    karbohidrat: 290,
    kalsium: 547,
    zatBesi: 21.5,
    fosfor: 917,
    vitaminA: 38630,
    tiamin: 0.8,
    vitaminC: 254,
    natrium: 400,
    kalium: 2156,
  ),
  65: KidneyDietNutrition(
    energi: 2040,
    protein: 67,
    lemak: 68,
    karbohidrat: 293,
    kalsium: 579,
    zatBesi: 24,
    fosfor: 957,
    vitaminA: 38643,
    tiamin: 0.8,
    vitaminC: 254,
    natrium: 400,
    kalium: 2156,
  ),
  70: KidneyDietNutrition(
    energi: 2130,
    protein: 72,
    lemak: 72,
    karbohidrat: 301,
    kalsium: 583,
    zatBesi: 24.8,
    fosfor: 1013,
    vitaminA: 38652,
    tiamin: 0.8,
    vitaminC: 423,
    natrium: 400,
    kalium: 2288,
  ),
};

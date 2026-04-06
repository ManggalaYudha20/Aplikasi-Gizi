// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\kidney_calculation\services\kidney_meal_planner_service.dart

import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/data/models/kidney_standard_food_model.dart';

/// Menyediakan daftar bahan makanan mentah (standar buku) per target protein diet ginjal.
class KidneyMealPlans {
  KidneyMealPlans._(); // Prevent instantiation — semua member bersifat static

  static final Map<int, List<KidneyStandardFoodItem>> _mealPlans = {
    // ── Pre-dialisis ───────────────────────────────────────────────────────────
    30: [
      KidneyStandardFoodItem(name: 'Beras', weight: 100, urt: '1 ½ gls nasi'),
      KidneyStandardFoodItem(name: 'Telur Ayam', weight: 50, urt: '1 btr'),
      KidneyStandardFoodItem(name: 'Daging Sapi', weight: 40, urt: '1 ptg sdg'),
      KidneyStandardFoodItem(name: 'Sayur', weight: 100, urt: '1 gls'),
      KidneyStandardFoodItem(name: 'Buah', weight: 150, urt: '1 ½ ptg'),
      KidneyStandardFoodItem(name: 'Minyak', weight: 40, urt: ''),
      KidneyStandardFoodItem(name: 'Madu', weight: 20, urt: '2 sdm'),
      KidneyStandardFoodItem(
        name: 'Kue Protein Rendah',
        weight: 150,
        urt: '2 porsi',
      ),
    ],
    35: [
      KidneyStandardFoodItem(name: 'Beras', weight: 100, urt: '1 ½ gls nasi'),
      KidneyStandardFoodItem(name: 'Telur Ayam', weight: 50, urt: '1 btr'),
      KidneyStandardFoodItem(name: 'Daging Sapi', weight: 40, urt: '1 ptg sdg'),
      KidneyStandardFoodItem(name: 'Ayam', weight: 40, urt: '1 ptg sdg'),
      KidneyStandardFoodItem(name: 'Sayur', weight: 100, urt: '1 gls'),
      KidneyStandardFoodItem(name: 'Buah', weight: 150, urt: '1 ½ ptg'),
      KidneyStandardFoodItem(name: 'Minyak', weight: 40, urt: ''),
      KidneyStandardFoodItem(name: 'Gula', weight: 20, urt: ''),
      KidneyStandardFoodItem(name: 'Madu', weight: 20, urt: '2 sdm'),
      KidneyStandardFoodItem(
        name: 'Kue Protein Rendah',
        weight: 150,
        urt: '2 porsi',
      ),
    ],
    40: [
      KidneyStandardFoodItem(name: 'Beras', weight: 150, urt: '2 gls nasi'),
      KidneyStandardFoodItem(name: 'Telur Ayam', weight: 50, urt: '1 btr'),
      KidneyStandardFoodItem(name: 'Daging Sapi', weight: 40, urt: '1 ptg sdg'),
      KidneyStandardFoodItem(name: 'Ayam', weight: 40, urt: '1 ptg sdg'),
      KidneyStandardFoodItem(name: 'Tempe', weight: 25, urt: '1 ptg sdg'),
      KidneyStandardFoodItem(name: 'Sayur', weight: 100, urt: '1 gls'),
      KidneyStandardFoodItem(name: 'Buah', weight: 150, urt: '1 ½ ptg'),
      KidneyStandardFoodItem(name: 'Minyak', weight: 40, urt: ''),
      KidneyStandardFoodItem(name: 'Gula', weight: 20, urt: ''),
      KidneyStandardFoodItem(name: 'Madu', weight: 20, urt: '2 sdm'),
      KidneyStandardFoodItem(
        name: 'Kue Protein Rendah',
        weight: 150,
        urt: '2 porsi',
      ),
    ],
    // ── Hemodialisis ──────────────────────────────────────────────────────────
    60: [
      KidneyStandardFoodItem(name: 'Beras', weight: 200, urt: '3 gls nasi'),
      KidneyStandardFoodItem(name: 'Maizena', weight: 15, urt: '3 sdm'),
      KidneyStandardFoodItem(name: 'Telur Ayam', weight: 50, urt: '1 btr'),
      KidneyStandardFoodItem(name: 'Daging', weight: 50, urt: '1 ½ ptg sdg'),
      KidneyStandardFoodItem(name: 'Ayam', weight: 50, urt: '1 ¼ ptg sdg'),
      KidneyStandardFoodItem(name: 'Tempe', weight: 75, urt: '3 ptg sdg'),
      KidneyStandardFoodItem(name: 'Sayuran', weight: 200, urt: '2 gls'),
      KidneyStandardFoodItem(name: 'Pepaya', weight: 300, urt: '3 ptg sdg'),
      KidneyStandardFoodItem(name: 'Minyak', weight: 30, urt: '3 sdm'),
      KidneyStandardFoodItem(name: 'Gula Pasir', weight: 50, urt: '4 sdm'),
      KidneyStandardFoodItem(name: 'Tepung Susu', weight: 10, urt: '2 sdm'),
      KidneyStandardFoodItem(name: 'Susu', weight: 100, urt: '½ gls'),
    ],
    65: [
      KidneyStandardFoodItem(name: 'Beras', weight: 200, urt: '3 gls nasi'),
      KidneyStandardFoodItem(name: 'Maizena', weight: 15, urt: '3 sdm'),
      KidneyStandardFoodItem(name: 'Telur Ayam', weight: 50, urt: '1 btr'),
      KidneyStandardFoodItem(name: 'Daging', weight: 50, urt: '1 ½ ptg sdg'),
      KidneyStandardFoodItem(name: 'Ayam', weight: 50, urt: '1 ¼ ptg sdg'),
      KidneyStandardFoodItem(name: 'Tempe', weight: 100, urt: '4 ptg sdg'),
      KidneyStandardFoodItem(name: 'Sayuran', weight: 200, urt: '2 gls'),
      KidneyStandardFoodItem(name: 'Pepaya', weight: 300, urt: '3 ptg sdg'),
      KidneyStandardFoodItem(name: 'Minyak', weight: 30, urt: '3 sdm'),
      KidneyStandardFoodItem(name: 'Gula Pasir', weight: 50, urt: '4 sdm'),
      KidneyStandardFoodItem(name: 'Tepung Susu', weight: 10, urt: '2 sdm'),
      KidneyStandardFoodItem(name: 'Susu', weight: 100, urt: '½ gls'),
    ],
    70: [
      KidneyStandardFoodItem(name: 'Beras', weight: 210, urt: '3 ¼ gls nasi'),
      KidneyStandardFoodItem(name: 'Maizena', weight: 15, urt: '3 sdm'),
      KidneyStandardFoodItem(name: 'Telur Ayam', weight: 50, urt: '1 btr'),
      KidneyStandardFoodItem(name: 'Daging', weight: 75, urt: '2 ptg sdg'),
      KidneyStandardFoodItem(name: 'Ayam', weight: 50, urt: '1 ¼ ptg sdg'),
      KidneyStandardFoodItem(name: 'Tempe', weight: 100, urt: '4 ptg sdg'),
      KidneyStandardFoodItem(name: 'Sayuran', weight: 200, urt: '2 gls'),
      KidneyStandardFoodItem(name: 'Pepaya', weight: 300, urt: '3 ptg sdg'),
      KidneyStandardFoodItem(name: 'Minyak', weight: 30, urt: '3 sdm'),
      KidneyStandardFoodItem(name: 'Gula Pasir', weight: 50, urt: '4 sdm'),
      KidneyStandardFoodItem(name: 'Tepung Susu', weight: 10, urt: '2 sdm'),
      KidneyStandardFoodItem(name: 'Susu', weight: 100, urt: '½ gls'),
    ],
  };

  /// Mengembalikan daftar bahan makanan untuk [protein] tertentu, atau `null`.
  static List<KidneyStandardFoodItem>? getPlan(int protein) =>
      _mealPlans[protein];

  /// Mengembalikan daftar bahan makanan untuk [proteinTarget] tertentu.
  /// Fallback ke level 40 g jika target tidak ditemukan.
  static List<KidneyStandardFoodItem> getPlanFor(int proteinTarget) =>
      _mealPlans[proteinTarget] ?? _mealPlans[40]!;
}

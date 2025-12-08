// lib/src/features/disease_calculation/services/kidney_meal_planner_service.dart

// Kelas untuk merepresentasikan setiap item makanan dalam diet
class FoodItem {
  final String name;
  final int weight;
  final String urt; // Ukuran Rumah Tangga

  FoodItem({required this.name, required this.weight, required this.urt});
}

// Kelas untuk menampung seluruh data diet berdasarkan kadar protein
class KidneyMealPlans {
  static final Map<int, List<FoodItem>> _mealPlans = {
    30: [
      FoodItem(name: 'Beras', weight: 100, urt: '1 ½ gls nasi'),
      FoodItem(name: 'Telur Ayam', weight: 50, urt: '1 btr'),
      FoodItem(name: 'Daging Sapi', weight: 40, urt: '1 ptg sdg'),
      FoodItem(name: 'Sayur', weight: 100, urt: '1 gls'),
      FoodItem(name: 'Buah', weight: 150, urt: '1 ½ ptg'),
      FoodItem(name: 'Minyak', weight: 40, urt: ''),
      FoodItem(name: 'Madu', weight: 20, urt: '2 sdm'),
      FoodItem(name: 'Kue Protein Rendah', weight: 150, urt: '2 porsi'),
    ],
    35: [
      FoodItem(name: 'Beras', weight: 100, urt: '1 ½ gls nasi'),
      FoodItem(name: 'Telur Ayam', weight: 50, urt: '1 btr'),
      FoodItem(name: 'Daging Sapi', weight: 40, urt: '1 ptg sdg'),
      FoodItem(name: 'Ayam', weight: 40, urt: '1 ptg sdg'),
      FoodItem(name: 'Sayur', weight: 100, urt: '1 gls'),
      FoodItem(name: 'Buah', weight: 150, urt: '1 ½ ptg'),
      FoodItem(name: 'Minyak', weight: 40, urt: ''),
      FoodItem(name: 'Gula', weight: 20, urt: ''),
      FoodItem(name: 'Madu', weight: 20, urt: '2 sdm'),
      FoodItem(name: 'Kue Protein Rendah', weight: 150, urt: '2 porsi'),
    ],
    40: [
      FoodItem(name: 'Beras', weight: 150, urt: '2 gls nasi'),
      FoodItem(name: 'Telur Ayam', weight: 50, urt: '1 btr'),
      FoodItem(name: 'Daging Sapi', weight: 40, urt: '1 ptg sdg'),
      FoodItem(name: 'Ayam', weight: 40, urt: '1 ptg sdg'),
      FoodItem(name: 'Tempe', weight: 25, urt: '1 ptg sdg'),
      FoodItem(name: 'Sayur', weight: 100, urt: '1 gls'),
      FoodItem(name: 'Buah', weight: 150, urt: '1 ½ ptg'),
      FoodItem(name: 'Minyak', weight: 40, urt: ''),
      FoodItem(name: 'Gula', weight: 20, urt: ''),
      FoodItem(name: 'Madu', weight: 20, urt: '2 sdm'),
      FoodItem(name: 'Kue Protein Rendah', weight: 150, urt: '2 porsi'),
    ],
    60: [
      FoodItem(name: 'Beras', weight: 200, urt: '3 gls nasi'),
      FoodItem(name: 'Maizena', weight: 15, urt: '3 sdm'),
      FoodItem(name: 'Telur Ayam', weight: 50, urt: '1 btr'),
      FoodItem(name: 'Daging', weight: 50, urt: '1 ½ ptg sdg'),
      FoodItem(name: 'Ayam', weight: 50, urt: '1 ¼ ptg sdg'),
      FoodItem(name: 'Tempe', weight: 75, urt: '3 ptg sdg'),
      FoodItem(name: 'Sayuran', weight: 200, urt: '2 gls'),
      FoodItem(name: 'Pepaya', weight: 300, urt: '3 ptg sdg'),
      FoodItem(name: 'Minyak', weight: 30, urt: '3 sdm'),
      FoodItem(name: 'Gula Pasir', weight: 50, urt: '4 sdm'),
      FoodItem(name: 'Tepung Susu', weight: 10, urt: '2 sdm'),
      FoodItem(name: 'Susu', weight: 100, urt: '½ gls'),
    ],
    65: [
      FoodItem(name: 'Beras', weight: 200, urt: '3 gls nasi'),
      FoodItem(name: 'Maizena', weight: 15, urt: '3 sdm'),
      FoodItem(name: 'Telur Ayam', weight: 50, urt: '1 btr'),
      FoodItem(name: 'Daging', weight: 50, urt: '1 ½ ptg sdg'),
      FoodItem(name: 'Ayam', weight: 50, urt: '1 ¼ ptg sdg'),
      FoodItem(name: 'Tempe', weight: 100, urt: '4 ptg sdg'),
      FoodItem(name: 'Sayuran', weight: 200, urt: '2 gls'),
      FoodItem(name: 'Pepaya', weight: 300, urt: '3 ptg sdg'),
      FoodItem(name: 'Minyak', weight: 30, urt: '3 sdm'),
      FoodItem(name: 'Gula Pasir', weight: 50, urt: '4 sdm'),
      FoodItem(name: 'Tepung Susu', weight: 10, urt: '2 sdm'),
      FoodItem(name: 'Susu', weight: 100, urt: '½ gls'),
    ],
    70: [
      FoodItem(name: 'Beras', weight: 210, urt: '3 ¼ gls nasi'),
      FoodItem(name: 'Maizena', weight: 15, urt: '3 sdm'),
      FoodItem(name: 'Telur Ayam', weight: 50, urt: '1 btr'),
      FoodItem(name: 'Daging', weight: 75, urt: '2 ptg sdg'),
      FoodItem(name: 'Ayam', weight: 50, urt: '1 ¼ ptg sdg'),
      FoodItem(name: 'Tempe', weight: 100, urt: '4 ptg sdg'),
      FoodItem(name: 'Sayuran', weight: 200, urt: '2 gls'),
      FoodItem(name: 'Pepaya', weight: 300, urt: '3 ptg sdg'),
      FoodItem(name: 'Minyak', weight: 30, urt: '3 sdm'),
      FoodItem(name: 'Gula Pasir', weight: 50, urt: '4 sdm'),
      FoodItem(name: 'Tepung Susu', weight: 10, urt: '2 sdm'),
      FoodItem(name: 'Susu', weight: 100, urt: '½ gls'),
    ],
  };

  // Method untuk mendapatkan daftar makanan berdasarkan diet protein
  static List<FoodItem>? getPlan(int protein) {
    return _mealPlans[protein];
  }

  static List<FoodItem> getPlanFor(int proteinTarget) {
    // Jika target persis ada (30, 35, 40...) ambil. 
    // Jika tidak, ambil yang terdekat atau default 60g.
    if (_mealPlans.containsKey(proteinTarget)) {
      return _mealPlans[proteinTarget]!;
    }
    // Fallback logic
    return _mealPlans[40]!; 
  }
}
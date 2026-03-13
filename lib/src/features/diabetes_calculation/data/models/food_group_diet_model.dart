// lib/src/features/diabetes_calculation/data/models/food_group_diet_model.dart

/// Standar diet golongan bahan makanan berdasarkan tingkat kalori.
class FoodGroupDiet {
  final String calorieLevel;
  final double nasiP;
  final double ikanP;
  final double dagingP;
  final String sayuranA;
  final double sayuranB;
  final double buah;
  final double susu;
  final double minyak;
  final double tempeP;

  FoodGroupDiet({
    required this.calorieLevel,
    required this.nasiP,
    required this.ikanP,
    required this.dagingP,
    required this.sayuranA,
    required this.sayuranB,
    required this.buah,
    required this.susu,
    required this.minyak,
    required this.tempeP,
  });
}
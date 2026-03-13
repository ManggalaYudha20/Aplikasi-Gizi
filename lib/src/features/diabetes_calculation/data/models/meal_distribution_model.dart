// lib/src/features/diabetes_calculation/data/models/meal_distribution_model.dart

/// Data nutrisi per satu waktu makan (pagi / snack / siang / malam).
class MealDistribution {
  final double nasiP;
  final double ikanP;
  final double dagingP;
  final String sayuranA; // 'S' = sekehendak, '' = tidak ada
  final double sayuranB;
  final double buah;
  final double susu;
  final double tempeP;
  final double minyak;

  MealDistribution({
    this.nasiP = 0,
    this.ikanP = 0,
    this.dagingP = 0,
    this.sayuranA = '',
    this.sayuranB = 0,
    this.buah = 0,
    this.susu = 0,
    this.tempeP = 0,
    this.minyak = 0,
  });
}

/// Pembagian makanan seluruh hari: pagi, snack pagi, siang, snack sore, malam.
class DailyMealDistribution {
  final String calorieLevel;
  final MealDistribution pagi;
  final MealDistribution snackPagi;
  final MealDistribution siang;
  final MealDistribution snackSore;
  final MealDistribution malam;

  DailyMealDistribution({
    required this.calorieLevel,
    required this.pagi,
    required this.snackPagi,
    required this.siang,
    required this.snackSore,
    required this.malam,
  });
}
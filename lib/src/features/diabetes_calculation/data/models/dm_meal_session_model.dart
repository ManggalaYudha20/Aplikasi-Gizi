// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\diabetes_calculation\data\models\dm_meal_session_model.dart

import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/data/models/diet_info_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/data/models/food_group_diet_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/data/models/meal_distribution_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/data/models/food_item_model.dart';

// ---------------------------------------------------------------------------
// Menu Items & Sessions (dipakai oleh DiabetesMealPlannerService dan UI)
// ---------------------------------------------------------------------------

/// Satu item makanan dalam satu sesi waktu makan pada tampilan UI.
class DmMenuItem {
  final String categoryLabel; // Label tampilan, mis. "Lauk Hewani"
  String foodName; // Nama makanan, mis. "Ayam Goreng"
  dynamic portion; // Porsi: angka (double) atau 'S' (sekehendak)
  FoodItem? foodData; // Data lengkap dari Firestore (untuk hitung gizi)

  DmMenuItem({
    required this.categoryLabel,
    required this.foodName,
    required this.portion,
    this.foodData,
  });
}

/// Satu sesi waktu makan, berisi nama sesi dan daftar menu.
class DmMealSession {
  final String sessionName;
  final List<DmMenuItem> items;

  DmMealSession({required this.sessionName, required this.items});
}

// ---------------------------------------------------------------------------
// Hasil Kalkulasi Diabetes (dipakai oleh DiabetesCalculatorService dan UI)
// ---------------------------------------------------------------------------

/// Seluruh hasil kalkulasi kebutuhan energi diabetes untuk satu pasien.
class DiabetesCalculationResult {
  final double bbIdeal;
  final double bmr;
  final double totalCalories;
  final double ageCorrection;
  final double activityCorrection;
  final double weightCorrection;
  final String bmiCategory;
  final DietInfo dietInfo;
  final FoodGroupDiet foodGroupDiet;
  final DailyMealDistribution dailyMealDistribution;
  final double calculatedProteinGram;
  final double calculatedFatGram;
  final double calculatedCarbsGram;

  DiabetesCalculationResult({
    required this.bbIdeal,
    required this.bmr,
    required this.totalCalories,
    required this.ageCorrection,
    required this.activityCorrection,
    required this.weightCorrection,
    required this.bmiCategory,
    required this.dietInfo,
    required this.foodGroupDiet,
    required this.dailyMealDistribution,
    required this.calculatedProteinGram,
    required this.calculatedFatGram,
    required this.calculatedCarbsGram,
  });
}

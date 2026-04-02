// lib/src/features/diabetes_calculation/services/diabetes_calculator_service.dart

import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/data/models/diet_info_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/data/models/dm_meal_session_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/data/models/food_group_diet_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/data/models/meal_distribution_model.dart';

class DiabetesCalculatorService {
  DiabetesCalculationResult calculate({
    required int age,
    required double weight,
    required double height,
    required String gender,
    required String activity,
    required String hospitalizedStatus,
    required double stressMetabolic,
  }) {
    final bbIdeal = _calculateBBIdeal(height, gender);
    final bmiCategory = _calculateBMICategory(weight, height);
    final bmr = (gender == 'Laki-laki') ? bbIdeal * 30 : bbIdeal * 25;

    double activityFactor = 0;
    switch (activity) {
      case 'Bed rest':
        activityFactor = 0.1;
        break;
      case 'Ringan':
        activityFactor = 0.2;
        break;
      case 'Sedang':
        activityFactor = 0.3;
        break;
      case 'Berat':
        activityFactor = 0.4;
        break;
    }

    final activityCorrection = activityFactor * bmr;
    final weightCorrection = _calculateWeightCorrection(bmiCategory, bmr);

    double totalCalories = bmr + activityCorrection + weightCorrection;

    double ageCorrection = 0;
    if (age >= 70) {
      ageCorrection = bmr * 0.20;
    } else if (age >= 60) {
      ageCorrection = bmr * 0.10;
    } else if (age >= 40) {
      ageCorrection = bmr * 0.05;
    }
    totalCalories -= ageCorrection;

    if (hospitalizedStatus == 'Ya') {
      final stressMetabolicCorrection = (stressMetabolic / 100) * bmr;
      totalCalories += stressMetabolicCorrection;
    }

    final dietInfo = _getDietType(totalCalories);
    final foodGroupDiet = _getFoodGroupDiet(totalCalories);
    final dailyMealDistribution = _getDailyMealDistribution(totalCalories);
    final double proteinGram = (totalCalories * 0.15) / 4.0;
    final double fatGram = (totalCalories * 0.25) / 9.0;
    final double carbsGram = (totalCalories * 0.60) / 4.0;

    return DiabetesCalculationResult(
      bbIdeal: bbIdeal,
      bmr: bmr,
      totalCalories: totalCalories,
      ageCorrection: ageCorrection,
      activityCorrection: activityCorrection,
      weightCorrection: weightCorrection,
      bmiCategory: bmiCategory,
      dietInfo: dietInfo,
      foodGroupDiet: foodGroupDiet,
      dailyMealDistribution: dailyMealDistribution,
      calculatedProteinGram: proteinGram,
      calculatedFatGram: fatGram,
      calculatedCarbsGram: carbsGram,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  double _calculateBBIdeal(double height, String gender) {
    if (gender == 'Laki-laki') {
      return height >= 160 ? (height - 100) * 0.9 : height - 100;
    } else {
      return height >= 150 ? (height - 100) * 0.9 : height - 100;
    }
  }

  String _calculateBMICategory(double weight, double height) {
    final bmi = weight / ((height / 100) * (height / 100));
    if (bmi < 18.5) return 'Kurang';
    if (bmi < 23) return 'Normal';
    if (bmi < 25) return 'Lebih';
    return 'Gemuk';
  }

  double _calculateWeightCorrection(String bmiCategory, double bmr) {
    switch (bmiCategory) {
      case 'Gemuk':
        return -0.2 * bmr;
      case 'Lebih':
        return -0.1 * bmr;
      case 'Kurang':
        return 0.2 * bmr;
      default:
        return 0;
    }
  }

  DietInfo _getDietType(double totalCalories) {
    if (totalCalories < 1200) {
      return DietInfo(name: 'Diet I (1100 kkal)', protein: 43, fat: 30, carbohydrate: 172);
    }
    if (totalCalories < 1400) {
      return DietInfo(name: 'Diet II (1300 kkal)', protein: 45, fat: 35, carbohydrate: 192);
    }
    if (totalCalories < 1600) {
      return DietInfo(name: 'Diet III (1500 kkal)', protein: 51.5, fat: 36.5, carbohydrate: 235);
    }
    if (totalCalories < 1800) {
      return DietInfo(name: 'Diet IV (1700 kkal)', protein: 55.5, fat: 36.5, carbohydrate: 275);
    }
    if (totalCalories < 2000) {
      return DietInfo(name: 'Diet V (1900 kkal)', protein: 60, fat: 48, carbohydrate: 299);
    }
    if (totalCalories < 2200) {
      return DietInfo(name: 'Diet VI (2100 kkal)', protein: 62, fat: 53, carbohydrate: 319);
    }
    if (totalCalories < 2400) {
      return DietInfo(name: 'Diet VII (2300 kkal)', protein: 73, fat: 59, carbohydrate: 369);
    }
    return DietInfo(name: 'Diet VIII (2500 kkal)', protein: 80, fat: 62, carbohydrate: 396);
  }

  FoodGroupDiet _getFoodGroupDiet(double totalCalories) {
    if (totalCalories < 1200) {
      return FoodGroupDiet(
        calorieLevel: '1100 kkal', nasiP: 2.5, ikanP: 2, dagingP: 1, tempeP: 2,
        sayuranA: 'S', sayuranB: 2, buah: 4, susu: 0, minyak: 3,
      );
    }
    if (totalCalories < 1400) {
      return FoodGroupDiet(
        calorieLevel: '1300 kkal', nasiP: 3, ikanP: 2, dagingP: 1, tempeP: 2,
        sayuranA: 'S', sayuranB: 2, buah: 4, susu: 0, minyak: 4,
      );
    }
    if (totalCalories < 1600) {
      return FoodGroupDiet(
        calorieLevel: '1500 kkal', nasiP: 4, ikanP: 2, dagingP: 1, tempeP: 2.5,
        sayuranA: 'S', sayuranB: 2, buah: 4, susu: 0, minyak: 4,
      );
    }
    if (totalCalories < 1800) {
      return FoodGroupDiet(
        calorieLevel: '1700 kkal', nasiP: 5, ikanP: 2, dagingP: 1, tempeP: 2.5,
        sayuranA: 'S', sayuranB: 2, buah: 4, susu: 0, minyak: 4,
      );
    }
    if (totalCalories < 2000) {
      return FoodGroupDiet(
        calorieLevel: '1900 kkal', nasiP: 5.5, ikanP: 2, dagingP: 1, tempeP: 3,
        sayuranA: 'S', sayuranB: 2, buah: 4, susu: 0, minyak: 6,
      );
    }
    if (totalCalories < 2200) {
      return FoodGroupDiet(
        calorieLevel: '2100 kkal', nasiP: 6, ikanP: 2, dagingP: 1, tempeP: 3,
        sayuranA: 'S', sayuranB: 2, buah: 4, susu: 0, minyak: 7,
      );
    }
    if (totalCalories < 2400) {
      return FoodGroupDiet(
        calorieLevel: '2300 kkal', nasiP: 7, ikanP: 2, dagingP: 1, tempeP: 3,
        sayuranA: 'S', sayuranB: 2, buah: 4, susu: 1, minyak: 7,
      );
    }
    return FoodGroupDiet(
      calorieLevel: '2500 kkal', nasiP: 7.5, ikanP: 2, dagingP: 1, tempeP: 5,
      sayuranA: 'S', sayuranB: 2, buah: 4, susu: 1, minyak: 7,
    );
  }

  DailyMealDistribution _getDailyMealDistribution(double totalCalories) {
    if (totalCalories < 1200) {
      return DailyMealDistribution(
        calorieLevel: '1100 kkal',
        pagi: MealDistribution(nasiP: 0.5, ikanP: 1, sayuranA: 'S', minyak: 1),
        snackPagi: MealDistribution(buah: 1),
        siang: MealDistribution(nasiP: 1, dagingP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 1),
        snackSore: MealDistribution(buah: 1),
        malam: MealDistribution(nasiP: 1, ikanP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 1),
      );
    }
    if (totalCalories < 1400) {
      return DailyMealDistribution(
        calorieLevel: '1300 kkal',
        pagi: MealDistribution(nasiP: 1, ikanP: 1, sayuranA: 'S', minyak: 1),
        snackPagi: MealDistribution(buah: 1),
        siang: MealDistribution(nasiP: 1, dagingP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 2),
        snackSore: MealDistribution(buah: 1),
        malam: MealDistribution(nasiP: 1, ikanP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 1),
      );
    }
    if (totalCalories < 1600) {
      return DailyMealDistribution(
        calorieLevel: '1500 kkal',
        pagi: MealDistribution(nasiP: 1, ikanP: 1, tempeP: 0.5, sayuranA: 'S', minyak: 1),
        snackPagi: MealDistribution(buah: 1),
        siang: MealDistribution(nasiP: 2, dagingP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 2),
        snackSore: MealDistribution(buah: 1),
        malam: MealDistribution(nasiP: 1, ikanP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 1),
      );
    }
    if (totalCalories < 1800) {
      return DailyMealDistribution(
        calorieLevel: '1700 kkal',
        pagi: MealDistribution(nasiP: 1, ikanP: 1, tempeP: 0.5, sayuranA: 'S', minyak: 1),
        snackPagi: MealDistribution(buah: 1),
        siang: MealDistribution(nasiP: 2, dagingP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 2),
        snackSore: MealDistribution(buah: 1),
        malam: MealDistribution(nasiP: 2, ikanP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 1),
      );
    }
    if (totalCalories < 2000) {
      return DailyMealDistribution(
        calorieLevel: '1900 kkal',
        pagi: MealDistribution(nasiP: 1.5, ikanP: 1, tempeP: 1, sayuranA: 'S', minyak: 2),
        snackPagi: MealDistribution(buah: 1),
        siang: MealDistribution(nasiP: 2, dagingP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 2),
        snackSore: MealDistribution(buah: 1),
        malam: MealDistribution(nasiP: 2, ikanP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 2),
      );
    }
    if (totalCalories < 2200) {
      return DailyMealDistribution(
        calorieLevel: '2100 kkal',
        pagi: MealDistribution(nasiP: 1.5, ikanP: 1, tempeP: 1, sayuranA: 'S', minyak: 2),
        snackPagi: MealDistribution(buah: 1),
        siang: MealDistribution(nasiP: 2.5, dagingP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 3),
        snackSore: MealDistribution(buah: 1),
        malam: MealDistribution(nasiP: 2, ikanP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 2),
      );
    }
    if (totalCalories < 2400) {
      return DailyMealDistribution(
        calorieLevel: '2300 kkal',
        pagi: MealDistribution(nasiP: 1.5, ikanP: 1, tempeP: 1, sayuranA: 'S', minyak: 2),
        snackPagi: MealDistribution(buah: 1, susu: 1),
        siang: MealDistribution(nasiP: 3, dagingP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 3),
        snackSore: MealDistribution(buah: 1),
        malam: MealDistribution(nasiP: 2.5, ikanP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 2),
      );
    }
    return DailyMealDistribution(
      calorieLevel: '2500 kkal',
      pagi: MealDistribution(nasiP: 2, ikanP: 1, tempeP: 1, sayuranA: 'S', minyak: 2),
      snackPagi: MealDistribution(buah: 1, susu: 1),
      siang: MealDistribution(nasiP: 3, dagingP: 1, tempeP: 2, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 3),
      snackSore: MealDistribution(buah: 1),
      malam: MealDistribution(nasiP: 2.5, ikanP: 1, tempeP: 2, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 2),
    );
  }
}
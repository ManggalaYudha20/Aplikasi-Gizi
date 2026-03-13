// lib/src/features/diabetes_calculation/services/diabetes_meal_planner_service.dart

import 'dart:math';

import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/data/models/dm_meal_session_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/data/models/meal_distribution_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/food_database_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';

class DiabetesMealPlannerService {
  final FoodDatabaseService _dbService;

  DiabetesMealPlannerService(this._dbService);

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<List<DmMealSession>> generateDailyPlan(DailyMealDistribution dist) async {
    return [
      await _createSession('Makan Pagi', dist.pagi),
      await _createSession('Pukul 10:00', dist.snackPagi),
      await _createSession('Makan Siang', dist.siang),
      await _createSession('Pukul 16:00', dist.snackSore),
      await _createSession('Makan Malam', dist.malam),
    ];
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<DmMealSession> _createSession(String name, MealDistribution mealDist) async {
    final List<DmMenuItem> items = [];

    // 1. Karbohidrat
    await _addItem(items, 'Karbohidrat', mealDist.nasiP, 'Serealia', fixedName: 'Nasi');

    // 2. Protein hewani
    if (mealDist.ikanP > 0) {
      await _addItem(items, 'Lauk Hewani (Ikan)', mealDist.ikanP, 'Ikan dsb');
    }
    if (mealDist.dagingP > 0) {
      await _addItem(items, 'Lauk Hewani (Daging)', mealDist.dagingP, 'Daging');
    }

    // 3. Protein nabati
    await _addItem(items, 'Lauk Nabati', mealDist.tempeP, 'Kacang');

    // 4. Sayuran A (bebas / sekehendak)
    if (mealDist.sayuranA == 'S' || mealDist.sayuranA.isNotEmpty) {
      final FoodItem? item = await _dbService.getRandomFoodItemByCategory('Sayur');
      items.add(DmMenuItem(
        categoryLabel: 'Sayuran A',
        foodName: item?.name ?? 'Sayuran A',
        portion: 'S',
        foodData: item,
      ));
    }

    // 5. Sayuran B
    await _addItem(items, 'Sayuran B', mealDist.sayuranB, 'Sayur');

    // 6. Buah (acak dari daftar prioritas)
    if (mealDist.buah > 0) {
      const opsiBuah = ['Apel', 'Jambu Biji', 'Pir', 'Jeruk', 'Alpukat'];
      final buahTerpilih = opsiBuah[Random().nextInt(opsiBuah.length)];
      await _addItem(items, 'Buah', mealDist.buah, 'Buah', fixedName: buahTerpilih);
    }

    // 7. Susu
    await _addItem(items, 'Susu', mealDist.susu, 'Susu');

    return DmMealSession(sessionName: name, items: items);
  }

  Future<void> _addItem(
    List<DmMenuItem> list,
    String label,
    double porsi,
    String firestoreCategory, {
    String? fixedName,
  }) async {
    if (porsi <= 0) return;

    final FoodItem? item = await _dbService.getRandomFoodItemByCategory(firestoreCategory);
    final finalName = fixedName ?? item?.name ?? 'Pilih $label';

    list.add(DmMenuItem(
      categoryLabel: label,
      foodName: finalName,
      portion: porsi,
      foodData: item,
    ));
  }
}
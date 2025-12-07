// lib/src/features/disease_calculation/services/diabetes_meal_planner_service.dart

import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/diabetes_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/food_database_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';
import 'dart:math';

/// Model untuk UI Menu
class DmMenuItem {
  final String categoryLabel; // Label Tampilan (misal: "Lauk Hewani")
  String foodName;            // Nama Makanan (misal: "Ayam Goreng")
  dynamic portion;            // Porsi (misal: 1.0 atau "Bebas")
  FoodItem? foodData;         // Data lengkap dari Firestore (untuk hitung gizi)

  DmMenuItem({
    required this.categoryLabel,
    required this.foodName,
    required this.portion,
    this.foodData,
  });
}

class DmMealSession {
  final String sessionName;
  final List<DmMenuItem> items;

  DmMealSession({required this.sessionName, required this.items});
}

class DiabetesMealPlannerService {
  final FoodDatabaseService _dbService;

  DiabetesMealPlannerService(this._dbService);

  // Fungsi Utama
  Future<List<DmMealSession>> generateDailyPlan(DailyMealDistribution dist) async {
    List<DmMealSession> dailyPlan = [];

    dailyPlan.add(await _createSession('Makan Pagi', dist.pagi));
    dailyPlan.add(await _createSession('Pukul 10:00', dist.snackPagi));
    dailyPlan.add(await _createSession('Makan Siang', dist.siang));
    dailyPlan.add(await _createSession('Pukul 16:00', dist.snackSore));
    dailyPlan.add(await _createSession('Makan Malam', dist.malam));

    return dailyPlan;
  }

  Future<DmMealSession> _createSession(String name, MealDistribution mealDist) async {
    final List<DmMenuItem> items = [];

    // --- Helper Mapping Kategori DM ke Kategori Firestore ---
    
    // 1. Karbohidrat (Nasi)
    // Firestore Category: SEREALIA atau UMBI (Kita pilih salah satu secara acak atau hardcode)
    await _addItem(items, 'Karbohidrat', mealDist.nasiP, 'Serealia', fixedName: 'Nasi');

    // 2. Protein Hewani (Ikan/Daging)
    // Di DM Calculator dipisah, kita gabung di UI atau loop satu per satu
    if (mealDist.ikanP > 0) await _addItem(items, 'Lauk Hewani (Ikan)', mealDist.ikanP, 'Ikan dsb');
    if (mealDist.dagingP > 0) await _addItem(items, 'Lauk Hewani (Daging)', mealDist.dagingP, 'Daging');
    
    // 3. Protein Nabati (Tempe)
    await _addItem(items, 'Lauk Nabati', mealDist.tempeP, 'Kacang');

    // 4. Sayuran A (Bebas)
   if (mealDist.sayuranA == 'S' || mealDist.sayuranA.isNotEmpty) {
      // Ambil data random dari database kategori 'Sayur'
      FoodItem? item = await _dbService.getRandomFoodItemByCategory('Sayur');

      items.add(DmMenuItem(
        categoryLabel: 'Sayuran A', 
        // Bagian ini diubah: Tidak ada lagi teks 'Ketimun / Selada / Tomat'
        // Jika data dari database (item) ada, pakai namanya. 
        // Jika null/gagal load, pakai teks umum 'Sayuran A'
        foodName: item?.name ?? 'Sayuran A', 
        portion: 'S', 
        foodData: item,
      ));
    }

    // 5. Sayuran B
    await _addItem(items, 'Sayuran B', mealDist.sayuranB, 'Sayur');

    // 6. Buah
    if (mealDist.buah > 0) {
      // Daftar buah prioritas
      List<String> opsiBuah = ['Apel', 'Jambu Biji', 'Pir', 'Jeruk', 'Alpukat'];
      // Pilih satu secara acak
      String buahTerpilih = opsiBuah[Random().nextInt(opsiBuah.length)];
      
      await _addItem(items, 'Buah', mealDist.buah, 'Buah', fixedName: buahTerpilih);
    }

    // 7. Susu
    await _addItem(items, 'Susu', mealDist.susu, 'Susu');

    return DmMealSession(sessionName: name, items: items);
  }

  // Helper Private untuk mengambil data
  Future<void> _addItem(
    List<DmMenuItem> list, 
    String label, 
    double porsi, 
    String firestoreCategory,
    {String? fixedName} 
  ) async {
    if (porsi <= 0) return;

    // Ambil dari Firestore lewat Service
    FoodItem? item = await _dbService.getRandomFoodItemByCategory(firestoreCategory);

    String finalName = fixedName ?? item?.name ?? 'Pilih $label';

    list.add(DmMenuItem(
      categoryLabel: label,
      foodName: finalName, 
      portion: porsi,
      foodData: item,
    ));
  }
}
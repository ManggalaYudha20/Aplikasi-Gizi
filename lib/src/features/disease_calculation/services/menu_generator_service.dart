// lib/src/features/disease_calculation/services/menu_generator_service.dart

import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/diabetes_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/food_database_service.dart';

// --- MODEL BARU UNTUK STRUKTUR DATA YANG DIINGINKAN ---

/// Merepresentasikan satu baris dalam tabel menu yang akan dibuat.
class MenuTableRow {
  final String foodGroup;   // e.g., "Nasi"
  final String menuItem;   // e.g., "Nasi Tim" (dari Firestore)
  final dynamic portion;      // e.g., 1.5 atau "S"

  MenuTableRow({
    required this.foodGroup,
    required this.menuItem,
    required this.portion,
  });
}

/// Merepresentasikan satu sesi makan (Pagi, Siang, dll.)
class GeneratedMeal {
  final String mealTime; // e.g., "Pagi"
  final List<MenuTableRow> rows;

  GeneratedMeal({required this.mealTime, required this.rows});
}


// --- SERVICE YANG DIPERBARUI ---

class MenuGeneratorService {
  final FoodDatabaseService _foodService = FoodDatabaseService();

  Future<List<GeneratedMeal>> generateMenu(
      DailyMealDistribution distribution) async {
    final List<GeneratedMeal> fullDayMenu = [];

    // Proses setiap waktu makan satu per satu
    final pagi = await _createMeal('Pagi', distribution.pagi);
    if (pagi.rows.isNotEmpty) fullDayMenu.add(pagi);

    final snackPagi = await _createMeal('Pukul 10.00', distribution.snackPagi);
    if (snackPagi.rows.isNotEmpty) fullDayMenu.add(snackPagi);

    final siang = await _createMeal('Siang', distribution.siang);
    if (siang.rows.isNotEmpty) fullDayMenu.add(siang);

    final snackSore = await _createMeal('Pukul 16.00', distribution.snackSore);
    if (snackSore.rows.isNotEmpty) fullDayMenu.add(snackSore);

    final malam = await _createMeal('Malam', distribution.malam);
    if (malam.rows.isNotEmpty) fullDayMenu.add(malam);

    return fullDayMenu;
  }

  /// Membuat satu sesi makan dengan menu dari Firestore
 Future<GeneratedMeal> _createMeal(String mealTime, MealDistribution meal) async {
    final List<MenuTableRow> tableRows = [];

    // Helper untuk memproses setiap bahan
    Future<void> processRow(String foodGroup, double portion) async {
      if (portion <= 0) return;
      
      // --- Pemanggilan Diperbarui: mealTime sekarang dilewatkan ---
      final foodItem = await _foodService.getRandomFoodItemByCategory(foodGroup);
     tableRows.add(
        MenuTableRow(
          foodGroup: foodGroup,
          menuItem: foodItem?.name ?? 'Pilihan $foodGroup', // Default text jika gagal fetch
          portion: portion,
        ),
      );
    }
    
    // ... (sisa kode di method ini tidak berubah)
    await processRow('Nasi', meal.nasiP);
    await processRow('Ikan', meal.ikanP);
    await processRow('Daging', meal.dagingP);
    await processRow('Tempe', meal.tempeP);
   if (meal.sayuranA.isNotEmpty) {
       tableRows.add(MenuTableRow(foodGroup: 'Sayuran A', menuItem: 'Sesuai Selera', portion: meal.sayuranA));
    }
    await processRow('Sayuran B', meal.sayuranB);
    await processRow('Buah', meal.buah);
    await processRow('Susu', meal.susu);
    await processRow('Minyak', meal.minyak);

    return GeneratedMeal(mealTime: mealTime, rows: tableRows);
  }
}
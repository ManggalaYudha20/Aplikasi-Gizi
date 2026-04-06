// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\diabetes_calculation\services\diabetes_meal_planner_service.dart

import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/data/models/dm_meal_session_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/expert_system/services/expert_system_engine.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/expert_system/services/food_database_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/data/models/food_item_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/expert_system/data/models/knowledge_base_model.dart'; // Ditambahkan untuk akses model MealItemRule
import 'dart:math';

class DiabetesMealPlannerService {
  final FoodDatabaseService _dbService;
  final ExpertSystemEngine _expertEngine;

  DiabetesMealPlannerService(this._dbService, this._expertEngine);

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Menghasilkan rencana menu berdasarkan input FAKTA (Kalori Total Pasien)
  Future<List<DmMealSession>> generateDailyPlan(
    double calculatedCalories,
  ) async {
    // 1. Siapkan Fakta Input Pasien
    final fact = PatientFact(
      diseaseId: 'dm',
      calculatedCalories: calculatedCalories,
    );

    // 2. Panggil Mesin Inferensi (Forward Chaining)
    final prescription = _expertEngine.forwardChain(fact);

    // 3. Ekstrak Resep dari Knowledge Base (Disesuaikan dengan model KB baru)
    final forbiddenKeywords = prescription.guideline.forbiddenFoods;

    // Asumsi: prescription.distribution mengembalikan objek DietDistributionRule
    final distributionMap = prescription.distribution.distribution;

    List<DmMealSession> dailySessions = [];

    // 4. Iterasi Dinamis Berdasarkan Jadwal (Pagi, Siang, Pukul 10.00, dll)
    for (var mealEntry in distributionMap.entries) {
      final String sessionName = mealEntry.key;
      // Disesuaikan: Value sekarang adalah List<MealItemRule>
      final List<MealItemRule> mealItems = mealEntry.value;

      List<DmMenuItem> sessionItems = [];

      // 5. Iterasi Item Makanan berdasarkan Rule (Karbohidrat, Protein Hewani, dll)
      for (var rule in mealItems) {
        final String categoryLabel = rule.categoryLabel;
        final dynamic portionValue = rule.portion;

        // Skip jika porsi 0 (contoh: tidak ada jatah nabati di pagi hari)
        if (portionValue is num && portionValue <= 0) continue;

        // Map kategori penukar medis ke kategori database (Serealia, Lauk Hewani, dll)
        String dbCategory = _mapCategoryToDb(categoryLabel);

        // Fetch makanan acak yang LOLOS filter pantangan (Constraint Filtering)
        FoodItem? selectedFood = await _getValidFoodItem(
          dbCategory,
          forbiddenKeywords,
        );

        String formattedPortion;
        if (portionValue is num) {
          // Jika nilainya sama dengan nilai integer-nya (contoh: 1.0 == 1), jadikan int
          formattedPortion = (portionValue == portionValue.toInt())
              ? portionValue.toInt().toString()
              : portionValue.toString();
        } else {
          // Tangkap nilai non-angka, misalnya string 'S'
          formattedPortion = portionValue.toString();
        }

        sessionItems.add(
          DmMenuItem(
            categoryLabel: categoryLabel,
            foodName:
                selectedFood?.name ?? 'Belum ada data $dbCategory yang aman',
            portion:
                formattedPortion, // Mengakomodasi double '1.5' atau String 'S'
            foodData: selectedFood,
          ),
        );
      }

      dailySessions.add(
        DmMealSession(sessionName: sessionName, items: sessionItems),
      );
    }

    return dailySessions;
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  /// Mapping nama Kategori Penukar dari Knowledge Base ke nama Kategori di Firebase/SQLite
  String _mapCategoryToDb(String label) {
    final l = label.toLowerCase();
    final random = Random();

    // 1. Karbohidrat -> Serealia atau Umbi
    if (l.contains('karbohidrat') || l.contains('nasi')) {
      final options = ['Serealia', 'Umbi']; // Diubah dari 'Umbi-umbi'
      return options[random.nextInt(options.length)];
    }

    // 2. Protein Hewani -> Daging, Ikan dsb, atau Telur
    if (l.contains('protein hewani') ||
        l.contains('ikan') ||
        l.contains('daging')) {
      final options = [
        'Daging', // Diubah dari 'Daging dan Unggas'
        'Ikan dsb', // Diubah dari 'Ikan, Kerang, Udang'
        'Telur',
      ];
      return options[random.nextInt(options.length)];
    }

    // 3. Protein Nabati -> Kacang
    if (l.contains('protein nabati') ||
        l.contains('tempe') ||
        l.contains('tahu')) {
      return 'Kacang'; // Diubah dari 'Kacang-kacangan'
    }

    // 4. Sayuran
    if (l.contains('sayuran') || l.contains('sayur')) {
      return 'Sayur'; // Diubah dari 'Sayuran'
    }

    // 5. Buah
    if (l.contains('buah')) {
      return 'Buah'; // Diubah dari 'Buah-buahan'
    }

    // 6. Susu
    if (l.contains('susu')) {
      return 'Susu';
    }

    // 7. Minyak / Lemak
    if (l.contains('minyak') || l.contains('lemak')) {
      return 'Lemak'; // Diubah dari 'Minyak dan Lemak'
    }

    return 'Serealia'; // Fallback aman
  }

  /// AI Constraint Filtering: Mencari makanan yang TIDAK mengandung kata kunci terlarang
  /// AI Constraint Filtering: Mengambil semua data, filter pantangan, lalu pilih acak
  Future<FoodItem?> _getValidFoodItem(
    String dbCategory,
    List<String> forbiddenKeywords,
  ) async {
    // 1. Tentukan kategori mana saja yang WAJIB berupa 'olahan'
    final List<String> wajibOlahan = [
      'Serealia',
      'Umbi',
      'Kacang',
      'Sayur',
      'Daging',
      'Ikan dsb',
      'Telur',
    ];

    // Cek apakah kategori saat ini ada di dalam daftar wajib olahan
    bool isOlahanRequired = wajibOlahan.contains(dbCategory);

    // 2. Ambil data dengan mengirimkan parameter requiresOlahan ke Database Service
    final allItems = await _dbService.getAllFoodItemsByCategory(
      dbCategory,
      requiresOlahan: isOlahanRequired, // <-- Lempar nilai boolean ke DB
    );

    if (allItems == null || allItems.isEmpty) return null;

    // 3. Filter khusus untuk pantangan DM (Tetap seperti semula)
    final validItems = allItems.where((item) {
      final itemName = item.name.toLowerCase();
      bool isForbidden = forbiddenKeywords.any(
        (keyword) => itemName.contains(keyword.toLowerCase()),
      );
      return !isForbidden;
    }).toList();

    if (validItems.isEmpty) return null;

    validItems.shuffle();
    return validItems.first;
  }
}

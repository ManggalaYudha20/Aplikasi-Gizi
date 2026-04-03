// lib/src/features/kidney_calculation/services/kidney_dynamic_menu_service.dart

import 'dart:math';

import 'package:aplikasi_diagnosa_gizi/src/shared/clinical_data/services/food_database_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/data/models/food_item_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/data/models/kidney_menu_models.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/data/models/kidney_knowledge_base.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/services/expert_system_engine.dart';

class KidneyDynamicMenuService {
  final FoodDatabaseService _dbService;
  final ExpertSystemEngine _expertEngine;

  KidneyDynamicMenuService(this._dbService, this._expertEngine);

  Future<List<KidneyMealSession>> generateDailyMenu(
    int proteinTarget, {
    bool isHighPotassium = false,
    double totalCalories = 0.0,
  }) async {
    final fact = PatientFact(
      diseaseId: 'ginjal',
      calculatedCalories: totalCalories,
      calculatedProtein: proteinTarget.toDouble(),
      complications: isHighPotassium ? ['hiperkalemia'] : [],
    );

    // 1. Eksekusi Forward Chaining
    final prescription = _expertEngine.forwardChain(fact);

    List<String> forbiddenKeywords = List.from(
      prescription.guideline.forbiddenFoods,
    );

    // 4. Gabungkan dengan pantangan kondisional (contoh: hiperkalemia) dari Knowledge Base
    for (String complication in fact.complications) {
      if (prescription.guideline.conditionalForbiddenFoods.containsKey(
        complication,
      )) {
        forbiddenKeywords.addAll(
          prescription.guideline.conditionalForbiddenFoods[complication]!,
        );
      }
    }

    // Aturan distribusi ini sekarang memegang kendali penuh atas menu
    final expertDistributionRules = prescription.distribution.distribution;

    final allFoods = await _dbService.getAllFoodItems();

    // 2. Saring makanan
    final safeFoods = allFoods.where((f) {
      final lowerName = f.name.toLowerCase();
      if (forbiddenKeywords.any(
        (pantangan) => lowerName.contains(pantangan.toLowerCase()),
      )) {
        return false;
      }
      return true;
    }).toList();

    // 3. Kelompokkan Makanan
    final Map<String, List<FoodItem>> foodMap = {
      'Pokok': [],
      'Lauk Hewani': [],
      'Lauk Nabati': [],
      'Sayuran': [],
      'Buah': [],
      'Susu': [],
      'Lemak': [],
      'Snack': [],
      'Pemanis': [],
    };

    for (var food in safeFoods) {
      final lowerName = food.name.toLowerCase();
      // Pemetaan Kategori
      if (foodMap.containsKey(food.kelompokMakanan)) {
        final categoryDb = food.kelompokMakanan.trim();
        String? targetCategory;

        // Pemetaan presisi dari Database ke Sistem Pakar
        switch (categoryDb) {
          case 'Serealia':
          case 'Umbi':
            targetCategory = 'Pokok';
            break;
          case 'Daging':
          case 'Ikan dsb':
          case 'Telur':
            targetCategory = 'Lauk Hewani';
            break;
          case 'Kacang':
            targetCategory = 'Lauk Nabati'; // Tahu, tempe, kacang hijau dsb
            break;
          case 'Sayur':
            targetCategory = 'Sayuran';
            break;
          case 'Buah':
            targetCategory = 'Buah';
            break;
          case 'Susu':
            targetCategory = 'Susu';
            break;
          case 'Lemak':
            targetCategory = 'Lemak';
            break;
          case 'Gula':
            targetCategory = 'Pemanis';
            break;
          default:
            targetCategory =
                null; // Mengabaikan 'Bumbu' atau kategori tidak dikenal
        }

        // Antisipasi khusus: Database tidak punya kategori "Snack"
        // Jadi kita override berdasarkan kata kunci pada nama makanan
        if (lowerName.contains('kue') ||
            lowerName.contains('bolu') ||
            lowerName.contains('biskuit') ||
            lowerName.contains('kripik') ||
            lowerName.contains('puding') ||
            lowerName.contains('roti')) {
          targetCategory = 'Snack';
        }

        if (targetCategory != null) {
          bool isAllowedBaseIngredient = true;

          // Validasi bahan dasar khusus diet ginjal sesuai knowledge base
          if (targetCategory == 'Lauk Hewani') {
            isAllowedBaseIngredient = allowedProteinSourcesPreDialisis.any(
              (bahan) => lowerName.contains(bahan.toLowerCase()),
            );
          } else if (targetCategory == 'Lauk Nabati') {
            isAllowedBaseIngredient = allowedVegetableSources.any(
              (bahan) => lowerName.contains(bahan.toLowerCase()),
            );
          }

          if (isAllowedBaseIngredient) {
            foodMap[targetCategory]!.add(food);
          }
        }
      }
    }

    // 4. Generate Menu Dinamis MURNI dari Sistem Pakar
    List<KidneyMealSession> dailyMenu = [];

    expertDistributionRules.forEach((sessionName, rules) {
      List<KidneyMenuItem> sessionItems = [];

      for (var rule in rules) {
        // Cari kandidat makanan berdasarkan kategori dari rule Sistem Pakar
        final candidates = foodMap[rule.categoryLabel] ?? [];
        final dbItem = _pickRandom(candidates);

        if (dbItem != null) {
          // Asumsi konversi: 1 porsi standar = 50 gram (Anda bisa mengubah rumus ini
          // menjadi lebih spesifik sesuai standar DKBM)
          final calculatedWeight = 50.0 * rule.portion;

          sessionItems.add(
            KidneyMenuItem(
              categoryLabel: rule.categoryLabel,
              foodName: dbItem.name,
              weight: calculatedWeight,
              urt: '${rule.portion} porsi',
              foodData: dbItem,
            ),
          );
        }
      }

      if (sessionItems.isNotEmpty) {
        dailyMenu.add(
          KidneyMealSession(sessionName: sessionName, items: sessionItems),
        );
      }
    });

    return dailyMenu;
  }

  FoodItem? _pickRandom(List<FoodItem>? list) {
    if (list == null || list.isEmpty) return null;
    return list[Random().nextInt(list.length)];
  }
}

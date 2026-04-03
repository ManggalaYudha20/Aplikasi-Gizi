// lib/src/features/kidney_calculation/services/kidney_dynamic_menu_service.dart

import 'dart:math';

import 'package:aplikasi_diagnosa_gizi/src/shared/clinical_data/services/food_database_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/data/models/food_item_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/data/models/kidney_menu_models.dart';
// kidney_knowledge_base tidak diimport langsung — sudah terdaftar di ExpertSystemEngine
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/services/expert_system_engine.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/services/kidney_meal_planner_service.dart';

class KidneyDynamicMenuService {
  final FoodDatabaseService _dbService;
  final ExpertSystemEngine _expertEngine;

  KidneyDynamicMenuService(this._dbService, this._expertEngine);

  Future<List<KidneyMealSession>> generateDailyMenu(
    int proteinTarget, {
    bool isHighPotassium = false,
    double totalCalories = 0.0,
  }) async {
    // ── 1. Forward Chaining → dapatkan guideline & distribusi sesi ────────────
    //    ExpertSystemEngine sudah mendaftarkan kidneyGuideline & kidneyDistributionRules
    //    secara internal. Cukup kirim PatientFact dengan diseaseId 'ginjal'.
    final fact = PatientFact(
      diseaseId: 'ginjal',
      calculatedCalories: totalCalories,
      calculatedProtein: proteinTarget.toDouble(),
      complications: isHighPotassium ? ['hiperkalemia'] : [],
    );

    final prescription = _expertEngine.forwardChain(fact);

    // ── 2. Kumpulkan pantangan (umum + kondisional) dari KB via prescription ──
    final List<String> forbiddenKeywords =
        List.from(prescription.guideline.forbiddenFoods);

    for (final complication in fact.complications) {
      final conditional =
          prescription.guideline.conditionalForbiddenFoods[complication];
      if (conditional != null) {
        forbiddenKeywords.addAll(conditional);
      }
    }

    // ── 3. Ambil bahan dasar dari KidneyMealPlans ─────────────────────────────
    //    KidneyMealPlans adalah "daftar belanja" resmi per target protein.
    //    Ini memastikan hanya bahan yang sesuai standar diet yang digunakan.
    final standardIngredients = KidneyMealPlans.getPlanFor(proteinTarget);

    // ── 4. Load DB & bangun lookup: keyword bahan standar → FoodItem lolos filter
    final allFoods = await _dbService.getAllFoodItems();

    final Map<String, List<FoodItem>> dbLookup = {};

    for (final ingredient in standardIngredients) {
      final keyword = ingredient.name.toLowerCase();

      final matches = allFoods.where((f) {
        final lowerName = f.name.toLowerCase();

        // Harus mengandung keyword bahan standar
        if (!lowerName.contains(keyword)) {
          return false;
        }

        // Tidak boleh mengandung kata pantangan dari KB
        if (forbiddenKeywords.any((p) => lowerName.contains(p.toLowerCase()))) {
          return false;
        }

        return true;
      }).toList();

      dbLookup[keyword] = matches;
    }

    // ── 5. Bangun categoryFoodMap dari bahan standar ──────────────────────────
    //    Setiap bahan standar dipetakan ke categoryLabel yang dipakai KB ginjal.
    //    Jika tidak ada item DB yang cocok, FoodItem sintetis dibuat sebagai fallback
    //    agar sesi menu tidak kosong.
    final Map<String, List<FoodItem>> categoryFoodMap = {
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

    for (final ingredient in standardIngredients) {
      final keyword = ingredient.name.toLowerCase();
      final category = _mapIngredientToCategory(ingredient.name);
      if (category == null) {
        continue;
      }

      final candidates = dbLookup[keyword] ?? [];

      if (candidates.isNotEmpty) {
        categoryFoodMap[category]?.addAll(candidates);
      } else {
        // Fallback sintetis — nama & berat dari KidneyMealPlans, gizi kosong
        categoryFoodMap[category]?.add(
          FoodItem(
            id: '',
            name: ingredient.name,
            code: '',
            mentahOlahan: '',
            kelompokMakanan: category,
            portionGram: ingredient.weight,
            air: 0,
            calories: 0,
            protein: 0,
            fat: 0,
            karbohidrat: 0,
            fiber: 0,
            abu: 0,
            kalsium: 0,
            fosfor: 0,
            besi: 0,
            natrium: 0,
            kalium: 0,
            tembaga: 0,
            seng: 0,
            retinol: 0,
            betaKaroten: 0,
            karotenTotal: 0,
            thiamin: 0,
            riboflavin: 0,
            niasin: 0,
            vitaminC: 0,
            bdd: 100,
          ),
        );
      }
    }

    // Deduplikasi per kategori
    for (final key in categoryFoodMap.keys) {
      final seen = <String>{};
      categoryFoodMap[key] =
          categoryFoodMap[key]!.where((f) => seen.add(f.name)).toList();
    }

    // ── 6. Susun menu harian mengikuti distribusi sesi dari KB ginjal ──────────
    //    prescription.distribution.distribution adalah Map<sessionName, List<MealItemRule>>
    //    yang berasal langsung dari kidneyDistributionRules (lihat ExpertSystemEngine).
    //    Setiap rule membawa: categoryLabel, weightGrams (berat final), dan urt.
    final expertDistribution = prescription.distribution.distribution;
    final List<KidneyMealSession> dailyMenu = [];

    expertDistribution.forEach((sessionName, rules) {
      final List<KidneyMenuItem> sessionItems = [];

      for (final rule in rules) {
        final candidates = categoryFoodMap[rule.categoryLabel] ?? [];
        final dbItem = _pickRandom(candidates);

        if (dbItem != null) {
          // Gunakan weightGrams langsung dari rule KB — ini sudah merupakan
          // berat final per sesi sesuai standar diet ginjal.
          // (portion di KB adalah representasi URT, bukan multiplier berat.)
          sessionItems.add(
            KidneyMenuItem(
              categoryLabel: rule.categoryLabel,
              foodName: dbItem.name,
              weight: rule.weightGrams ?? (50.0 * rule.portion),
             urt: rule.urt ?? '${rule.portion} porsi',
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

  // ---------------------------------------------------------------------------
  // Helper: peta nama bahan standar → categoryLabel KB ginjal
  // ---------------------------------------------------------------------------

  /// Mengembalikan categoryLabel yang dipakai Knowledge Base ginjal,
  /// atau null jika bahan tidak perlu masuk ke menu.
  String? _mapIngredientToCategory(String ingredientName) {
    final lower = ingredientName.toLowerCase();

    // Cek 'tepung susu' SEBELUM 'tepung' agar tidak salah masuk Pokok
    if (lower.contains('tepung susu')) {
      return 'Susu';
    }

    // Pokok
    if (lower.contains('beras') ||
        lower.contains('nasi') ||
        lower.contains('maizena') ||
        lower.contains('tepung')) {
      return 'Pokok';
    }

    // Lauk Hewani
    if (lower.contains('telur') ||
        lower.contains('daging') ||
        lower.contains('ayam') ||
        lower.contains('ikan') ||
        lower.contains('udang')) {
      return 'Lauk Hewani';
    }

    // Lauk Nabati
    if (lower.contains('tempe') ||
        lower.contains('tahu') ||
        lower.contains('kacang hijau')) {
      return 'Lauk Nabati';
    }

    // Sayuran
    if (lower.contains('sayur')) {
      return 'Sayuran';
    }

    // Buah
    if (lower.contains('buah') ||
        lower.contains('pepaya') ||
        lower.contains('jeruk') ||
        lower.contains('apel')) {
      return 'Buah';
    }

    // Susu
    if (lower.contains('susu')) {
      return 'Susu';
    }

    // Lemak
    if (lower.contains('minyak') || lower.contains('margarin')) {
      return 'Lemak';
    }

    // Pemanis
    if (lower.contains('gula') || lower.contains('madu')) {
      return 'Pemanis';
    }

    // Snack
    if (lower.contains('kue') ||
        lower.contains('bolu') ||
        lower.contains('biskuit') ||
        lower.contains('roti')) {
      return 'Snack';
    }

    return null;
  }

  FoodItem? _pickRandom(List<FoodItem>? list) {
    if (list == null || list.isEmpty) {
      return null;
    }
    return list[Random().nextInt(list.length)];
  }
}
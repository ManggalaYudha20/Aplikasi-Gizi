// lib/src/features/kidney_calculation/services/kidney_dynamic_menu_service.dart

import 'dart:math';

import 'package:aplikasi_diagnosa_gizi/src/features/expert_system/services/food_database_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/data/models/food_item_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/data/models/kidney_menu_models.dart';
// kidney_knowledge_base tidak diimport langsung — sudah terdaftar di ExpertSystemEngine
import 'package:aplikasi_diagnosa_gizi/src/features/expert_system/services/expert_system_engine.dart';
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
    final fact = PatientFact(
      diseaseId: 'ginjal',
      calculatedCalories: totalCalories,
      calculatedProtein: proteinTarget.toDouble(),
      complications: isHighPotassium ? ['hiperkalemia'] : [],
    );

    final prescription = _expertEngine.forwardChain(fact);

    // ── 2. Kumpulkan pantangan (umum + kondisional) dari KB via prescription ──
    final List<String> forbiddenKeywords = List.from(
      prescription.guideline.forbiddenFoods,
    );

    for (final complication in fact.complications) {
      final conditional =
          prescription.guideline.conditionalForbiddenFoods[complication];
      if (conditional != null) {
        forbiddenKeywords.addAll(conditional);
      }
    }

    // ── 3. Ambil bahan dasar dari KidneyMealPlans ─────────────────────────────
    final standardIngredients = KidneyMealPlans.getPlanFor(proteinTarget);

    final Map<String, List<String>> processedFoodMap = {
      'beras': [
        'nasi',
        'nasi tim',
        'nasi gurih',
        'nasi rames',
        'bubur tinotuan (manado)',
      ],
      'ayam': [
        'ayam goreng pasundan',
        'ayam goreng kalasan',
        'ayam taliwang, masakan',
        'kalio ayam, masakan',
      ],
      'telur': [
        'telur ayam, dadar, masakan',
        'telur bebek, dadar, masakan',
        'kalio telur, masakan',
        'tahu telur',
      ],
      'ikan': [
        'ikan bandeng presto',
        'ikan baung bakar',
        'ikan mas pepes',
        'ikan mujahir goreng',
        'ikan mujahir pepes',
        'ikan patin, bakar',
        'gulai ikan, masakan',
      ],
      'tahu': ['tahu goreng', 'kembang tahu rebus', 'moon tahu'],
      'tempe': [
        'tempe kedelai murni, goreng',
        'tempe pasar goreng',
        'keripik tempe',
      ],
      'sayur': [
        'sayur asem',
        'sayur sop',
        'cap cai, sayur',
        'asinan bogor, sayuran',
      ],
      'buah': ['pepaya ', 'pir', 'apel'],
    };

    // ── 4. Load DB & bangun lookup: keyword bahan standar -> FoodItem lolos filter
    final allFoods = await _dbService.getAllFoodItems();
    final Map<String, List<FoodItem>> dbLookup = {};

    for (final ingredient in standardIngredients) {
      final keyword = ingredient.name.toLowerCase();

      // --- PERBAIKAN 1: Tentukan matchedKey dengan mendeteksi isi keyword ---
      String? matchedKey;

      if (keyword.contains('beras') || keyword.contains('nasi')) {
        matchedKey = 'beras';
      } else if (keyword.contains('telur')) {
        matchedKey = 'telur';
      } else if (RegExp(r'\bayam\b').hasMatch(keyword)) {
        // Menggunakan Regex agar "bayam" tidak masuk ke "ayam"
        matchedKey = 'ayam';
      } else if (keyword.contains('ikan')) {
        matchedKey = 'ikan';
      } else if (keyword.contains('tahu')) {
        matchedKey = 'tahu';
      } else if (keyword.contains('tempe')) {
        matchedKey = 'tempe';
      } else if (keyword.contains('sayur')) {
        matchedKey = 'sayur';
      } else if (keyword.contains('buah')) {
        matchedKey = 'buah';
      }

      final matches = allFoods.where((f) {
        final lowerName = f.name.toLowerCase();

        bool isMatch = false;

        // --- PERBAIKAN 2: Gunakan matchedKey, bukan containsKey ---
        if (matchedKey != null && processedFoodMap.containsKey(matchedKey)) {
          isMatch = processedFoodMap[matchedKey]!.any((olahan) {
            String term = olahan.toLowerCase().trim();
            // Perbaikan Bug 'Pirous': Gunakan batas kata untuk buah bersuku kata pendek
            if (term == 'pir' || term == 'apel' || term == 'jeruk') {
              return RegExp(r'\b' + term + r'\b').hasMatch(lowerName);
            }
            // Untuk nama masakan panjang, tetap pakai contains
            return lowerName.contains(term);
          });
          
          if (isMatch && matchedKey == 'buah') {
            if (lowerName.contains('daun') ||
                lowerName.contains('sayur') ||
                lowerName.contains('bunga')) {
              isMatch = false; // Batalkan kecocokan
            }
          }
        } else {
          // Regex digunakan di sini juga untuk fallback agar akurat
          if (keyword == 'madu' || keyword == 'ayam') {
            isMatch = RegExp(r'\b' + keyword + r'\b').hasMatch(lowerName);
          } else if (keyword == 'minyak') {
            // --- PERBAIKAN BUG NASI MINYAK ---
            isMatch =
                RegExp(r'\bminyak\b').hasMatch(lowerName) &&
                !lowerName.contains('nasi') &&
                !lowerName.contains('mie') &&
                !lowerName.contains('kerupuk');
          } else {
            isMatch = lowerName.contains(keyword);
          }
        }

        if (!isMatch) return false;

        // Filter Pantangan: Tetap pastikan makanan tidak mengandung bahan terlarang
        if (forbiddenKeywords.any((p) => lowerName.contains(p.toLowerCase()))) {
          return false;
        }

        return true;
      }).toList();

      dbLookup[keyword] = matches;
    }

    // ── 5. Bangun categoryFoodMap dari bahan standar ──────────────────────────
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
        // Fallback sintetis
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
      categoryFoodMap[key] = categoryFoodMap[key]!
          .where((f) => seen.add(f.name))
          .toList();
    }

    // ── 6. Susun menu harian mengikuti distribusi sesi dari KB ginjal ──────────
    final expertDistribution = prescription.distribution.distribution;
    final List<KidneyMealSession> dailyMenu = [];

    expertDistribution.forEach((sessionName, rules) {
      final List<KidneyMenuItem> sessionItems = [];

      for (final rule in rules) {
        final candidates = categoryFoodMap[rule.categoryLabel] ?? [];
        final dbItem = _pickRandom(candidates);

        if (dbItem != null) {
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

  String? _mapIngredientToCategory(String ingredientName) {
    final lower = ingredientName.toLowerCase();

    // Cek 'tepung susu' SEBELUM 'tepung' agar tidak salah masuk Pokok
    if (lower.contains('tepung susu')) {
      return 'Susu';
    }

    // Pokok
    if (lower.contains('nasi') ||
        lower.contains('beras') ||
        lower.contains('maizena') ||
        lower.contains('tepung')) {
      return 'Pokok';
    }

    // Lauk Hewani
    if (lower.contains('telur') ||
        lower.contains('daging') ||
        RegExp(r'\bayam\b').hasMatch(lower) || // Perbaikan Bug "bayam" -> "ayam"
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
        (RegExp(r'\bpepaya\b').hasMatch(lower) &&
            !lower.contains('daun') &&
            !lower.contains('sayur')) ||
        RegExp(r'\bjeruk\b').hasMatch(lower) ||
        RegExp(r'\bapel\b').hasMatch(lower) ||
        RegExp(r'\bpir\b').hasMatch(lower)) {
      return 'Buah';
    }

    // Susu
    if (lower.contains('susu')) {
      return 'Susu';
    }

    // Lemak
    if ((RegExp(r'\bminyak\b').hasMatch(lower) && !lower.contains('nasi')) ||
        lower.contains('margarin')) {
      return 'Lemak';
    }

    // Pemanis
    // PERBAIKAN BUG MADURA: Menggunakan \b (word boundary) agar 'madura' tidak terdeteksi
    if (lower.contains('gula') || RegExp(r'\bmadu\b').hasMatch(lower)) {
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
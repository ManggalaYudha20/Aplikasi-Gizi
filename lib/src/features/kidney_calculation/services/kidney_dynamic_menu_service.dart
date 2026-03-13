// lib/src/features/kidney_calculation/services/kidney_dynamic_menu_service.dart

import 'dart:math';

import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/food_database_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/data/models/kidney_menu_models.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/data/models/kidney_standard_food_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/services/kidney_meal_planner_service.dart';

/// Menghasilkan menu harian dinamis berdasarkan target protein dan kondisi medis pasien.
class KidneyDynamicMenuService {
  final FoodDatabaseService _dbService;

  KidneyDynamicMenuService(this._dbService);

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Menghasilkan [List<KidneyMealSession>] untuk satu hari penuh.
  ///
  /// [proteinTarget]    : Level diet (30, 35, 40, 60, 65, atau 70 gram protein).
  /// [isHighPotassium]  : `true` jika pasien hiperkalemia — sayuran & buah tinggi
  ///                      kalium akan disaring sesuai buku hal. 249.
  Future<List<KidneyMealSession>> generateDailyMenu(
    int proteinTarget, {
    bool isHighPotassium = false,
  }) async {
    final allFoods = await _dbService.getAllFoodItems();

    // Saring makanan tinggi kalium jika pasien hiperkalemia
    final safeFoods = isHighPotassium
        ? allFoods.where((f) => !_isHighPotassiumFood(f.name)).toList()
        : allFoods;

    // Kelompokkan makanan berdasarkan kategori
    final Map<String, List<FoodItem>> foodMap = {
      'Pokok': [], 'Lauk Hewani': [], 'Lauk Nabati': [],
      'Sayuran': [], 'Buah': [], 'Susu': [],
      'Lemak': [], 'Snack': [], 'Pemanis': [],
    };

    for (var food in safeFoods) {
      if (foodMap.containsKey(food.kelompokMakanan)) {
        foodMap[food.kelompokMakanan]!.add(food);
      } else {
        final lower = food.name.toLowerCase();
        if (lower.contains('kue') || lower.contains('bolu')) {
          foodMap['Snack']?.add(food);
        } else if (lower.contains('gula') || lower.contains('madu')) {
          foodMap['Pemanis']?.add(food);
        } else if (lower.contains('minyak')) {
          foodMap['Lemak']?.add(food);
        }
      }
    }

    final List<KidneyStandardFoodItem> dailyIngredients =
        KidneyMealPlans.getPlanFor(proteinTarget);

    List<KidneyMenuItem> pagi      = [];
    List<KidneyMenuItem> snackPagi = [];
    List<KidneyMenuItem> siang     = [];
    List<KidneyMenuItem> snackSore = [];
    List<KidneyMenuItem> malam     = [];

    for (var ingredient in dailyIngredients) {
      await _distributeIngredient(
        ingredient, foodMap, pagi, snackPagi, siang, snackSore, malam,
      );
    }

    return [
      KidneyMealSession(sessionName: 'Makan Pagi (06.00 - 08.00)',     items: pagi),
      if (snackPagi.isNotEmpty)
        KidneyMealSession(sessionName: 'Selingan Pagi (10.00)',         items: snackPagi),
      KidneyMealSession(sessionName: 'Makan Siang (12.00 - 13.00)',    items: siang),
      if (snackSore.isNotEmpty)
        KidneyMealSession(sessionName: 'Selingan Sore (16.00)',         items: snackSore),
      KidneyMealSession(sessionName: 'Makan Malam (18.00 - 19.00)',    items: malam),
    ];
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Daftar makanan tinggi kalium sesuai buku hal. 249.
  bool _isHighPotassiumFood(String foodName) {
    final lower = foodName.toLowerCase();
    const forbidden = [
      'bayam', 'daun singkong', 'asparagus', 'kembang kol', 'kangkung',
      'pisang', 'belimbing', 'alpukat', 'nangka', 'durian',
    ];
    return forbidden.any((item) => lower.contains(item));
  }

  Future<void> _distributeIngredient(
    KidneyStandardFoodItem ingredient,
    Map<String, List<FoodItem>> foodMap,
    List<KidneyMenuItem> pagi,
    List<KidneyMenuItem> snackPagi,
    List<KidneyMenuItem> siang,
    List<KidneyMenuItem> snackSore,
    List<KidneyMenuItem> malam,
  ) async {
    final name   = ingredient.name.toLowerCase();
    final weight = ingredient.weight.toDouble();

    // 1. Beras / Nasi — dibagi 3 sesi makan utama
    if (name.contains('beras') || name.contains('nasi')) {
      final portion = weight / 3;
      final dbItem  = _pickRandom(foodMap['Pokok'], filterQuery: 'nasi');
      for (final list in [pagi, siang, malam]) {
        list.add(KidneyMenuItem(
          categoryLabel: 'Makanan Pokok',
          foodName: dbItem?.name ?? 'Nasi Putih',
          weight: portion,
          urt: '1/3 porsi harian',
          foodData: dbItem,
        ));
      }
      return;
    }

    // 2. Maizena / Tepung / Sagu — jadi kue snack pagi
    if (name.contains('maizena') || name.contains('tepung') || name.contains('sagu')) {
      snackPagi.add(KidneyMenuItem(
        categoryLabel: 'Kue / Snack RP',
        foodName: 'Kue Talam/Semprit (Bahan: ${ingredient.name})',
        weight: weight,
        urt: ingredient.urt,
      ));
      return;
    }

    // 3. Telur — sarapan pagi
    if (name.contains('telur')) {
      final dbItem = _pickRandom(foodMap['Lauk Hewani'], filterQuery: 'telur');
      pagi.add(KidneyMenuItem(
        categoryLabel: 'Lauk Hewani',
        foodName: dbItem?.name ?? 'Telur Rebus',
        weight: weight,
        urt: ingredient.urt,
        foodData: dbItem,
      ));
      return;
    }

    // 4. Daging Sapi — makan siang
    if (name.contains('daging') || name.contains('sapi')) {
      final dbItem = _pickRandom(foodMap['Lauk Hewani'], filterQuery: 'daging') ??
                     _pickRandom(foodMap['Lauk Hewani'], filterQuery: 'sapi');
      siang.add(KidneyMenuItem(
        categoryLabel: 'Lauk Hewani',
        foodName: dbItem?.name ?? 'Empal Daging',
        weight: weight,
        urt: ingredient.urt,
        foodData: dbItem,
      ));
      return;
    }

    // 5. Ayam / Ikan — makan malam
    if (name.contains('ayam') || name.contains('ikan')) {
      final isAyam = name.contains('ayam');
      final dbItem = _pickRandom(
        foodMap['Lauk Hewani'],
        filterQuery: isAyam ? 'ayam' : 'ikan',
      );
      malam.add(KidneyMenuItem(
        categoryLabel: 'Lauk Hewani',
        foodName: dbItem?.name ?? (isAyam ? 'Ayam Panggang' : 'Ikan Pepes'),
        weight: weight,
        urt: ingredient.urt,
        foodData: dbItem,
      ));
      return;
    }

    // 6. Tempe / Tahu — dibagi siang & malam jika berat ≥ 50 g
    if (name.contains('tempe') || name.contains('tahu')) {
      if (weight < 50) {
        final dbItem = _pickRandom(foodMap['Lauk Nabati'], filterQuery: name);
        siang.add(KidneyMenuItem(
          categoryLabel: 'Lauk Nabati',
          foodName: dbItem?.name ?? 'Tempe/Tahu Goreng',
          weight: weight,
          urt: ingredient.urt,
          foodData: dbItem,
        ));
      } else {
        final portion = weight / 2;
        final dbItem  = _pickRandom(foodMap['Lauk Nabati']);
        siang.add(KidneyMenuItem(
          categoryLabel: 'Lauk Nabati',
          foodName: dbItem?.name ?? 'Tempe Bacem',
          weight: portion,
          urt: '1/2 porsi',
          foodData: dbItem,
        ));
        malam.add(KidneyMenuItem(
          categoryLabel: 'Lauk Nabati',
          foodName: 'Olahan Tahu/Tempe',
          weight: portion,
          urt: '1/2 porsi',
          foodData: dbItem,
        ));
      }
      return;
    }

    // 7. Sayuran — dibagi siang & malam (2 jenis berbeda)
    if (name.contains('sayur')) {
      final portion  = weight / 2;
      final dbItemA  = _pickRandom(foodMap['Sayuran']);
      var   dbItemB  = _pickRandom(foodMap['Sayuran']);
      if ((foodMap['Sayuran']?.length ?? 0) > 1) {
        while (dbItemB == dbItemA) {
          dbItemB = _pickRandom(foodMap['Sayuran']);
        }
      }
      siang.add(KidneyMenuItem(
        categoryLabel: 'Sayuran',
        foodName: dbItemA?.name ?? 'Tumis Sayur',
        weight: portion,
        urt: '1/2 porsi (${ingredient.urt})',
        foodData: dbItemA,
      ));
      malam.add(KidneyMenuItem(
        categoryLabel: 'Sayuran',
        foodName: dbItemB?.name ?? 'Sup Sayur',
        weight: portion,
        urt: '1/2 porsi',
        foodData: dbItemB,
      ));
      return;
    }

    // 8. Buah / Pepaya — dibagi ke snack pagi & sore
    if (name.contains('buah') || name.contains('pepaya')) {
      final portion  = weight / 2;
      final dbItemA  = _pickRandom(foodMap['Buah']);
      final dbItemB  = _pickRandom(foodMap['Buah']);
      snackPagi.add(KidneyMenuItem(
        categoryLabel: 'Buah Potong',
        foodName: dbItemA?.name ?? 'Buah',
        weight: portion,
        urt: '1 ptg sdg',
        foodData: dbItemA,
      ));
      snackSore.add(KidneyMenuItem(
        categoryLabel: 'Buah Potong',
        foodName: dbItemB?.name ?? 'Buah',
        weight: portion,
        urt: '1 ptg sdg',
        foodData: dbItemB,
      ));
      return;
    }

    // 9. Gula / Madu — pemanis snack pagi
    if (name.contains('gula') || name.contains('madu')) {
      snackPagi.add(KidneyMenuItem(
        categoryLabel: 'Pemanis',
        foodName: ingredient.name,
        weight: weight,
        urt: ingredient.urt,
      ));
      return;
    }

    // Fallback — tambahkan ke makan siang
    siang.add(KidneyMenuItem(
      categoryLabel: 'Tambahan',
      foodName: ingredient.name,
      weight: weight,
      urt: ingredient.urt,
    ));
  }

  FoodItem? _pickRandom(List<FoodItem>? list, {String? filterQuery}) {
    if (list == null || list.isEmpty) return null;
    List<FoodItem> candidates = list;
    if (filterQuery != null) {
      final filtered = list
          .where((i) => i.name.toLowerCase().contains(filterQuery.toLowerCase()))
          .toList();
      if (filtered.isNotEmpty) candidates = filtered;
    }
    return candidates[Random().nextInt(candidates.length)];
  }
}
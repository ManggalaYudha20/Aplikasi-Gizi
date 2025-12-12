// lib/src/features/disease_calculation/services/kidney_dynamic_menu_service.dart

import 'dart:math';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_menu_models.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/food_database_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_meal_planner_service.dart' as planner; 
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';

class KidneyDynamicMenuService {
  final FoodDatabaseService _dbService;

  KidneyDynamicMenuService(this._dbService);

  /// Tambahkan parameter kondisi medis pasien (misal: Kalium Tinggi)
  Future<List<KidneyMealSession>> generateDailyMenu(int proteinTarget, {bool isHighPotassium = false}) async {
    final allFoods = await _dbService.getAllFoodItems();
    
    // Filter awal: Hapus makanan tinggi kalium jika pasien Hiperkalemia
    // Asumsi: FoodItem punya property `isHighPotassium` atau kita filter by nama (hardcode sesuai buku hal 249)
    final safeFoods = isHighPotassium 
        ? allFoods.where((f) => !_isHighPotassiumFood(f.name)).toList()
        : allFoods;

    // Mapping Kategori
    final Map<String, List<FoodItem>> foodMap = {
      'Pokok': [], 'Lauk Hewani': [], 'Lauk Nabati': [],
      'Sayuran': [], 'Buah': [], 'Susu': [],
      'Lemak': [], 'Snack': [], 'Pemanis': [],
    };

    for (var food in safeFoods) {
      if (foodMap.containsKey(food.kelompokMakanan)) {
        foodMap[food.kelompokMakanan]!.add(food);
      } else {
        final lowerName = food.name.toLowerCase();
        if (lowerName.contains('kue') || lowerName.contains('bolu')) {
           foodMap['Snack']?.add(food);
        } else if (lowerName.contains('gula') || lowerName.contains('madu')) {
           foodMap['Pemanis']?.add(food);
        } else if (lowerName.contains('minyak')) {
           foodMap['Lemak']?.add(food);
        }
      }
    }

    final List<planner.FoodItem> dailyIngredients = planner.KidneyMealPlans.getPlanFor(proteinTarget);

    List<KidneyMenuItem> pagi = [];
    List<KidneyMenuItem> snackPagi = [];
    List<KidneyMenuItem> siang = [];
    List<KidneyMenuItem> snackSore = [];
    List<KidneyMenuItem> malam = [];

    for (var ingredient in dailyIngredients) {
      await _distributeIngredient(
        ingredient, foodMap, pagi, snackPagi, siang, snackSore, malam
      );
    }

    return [
      KidneyMealSession(sessionName: 'Makan Pagi (06.00 - 08.00)', items: pagi),
      if (snackPagi.isNotEmpty) KidneyMealSession(sessionName: 'Selingan Pagi (10.00)', items: snackPagi),
      KidneyMealSession(sessionName: 'Makan Siang (12.00 - 13.00)', items: siang),
      if (snackSore.isNotEmpty) KidneyMealSession(sessionName: 'Selingan Sore (16.00)', items: snackSore),
      KidneyMealSession(sessionName: 'Makan Malam (18.00 - 19.00)', items: malam),
    ];
  }

  /// Helper filter berdasarkan Buku Hal 249
  bool _isHighPotassiumFood(String foodName) {
    final lower = foodName.toLowerCase();
    // Daftar hitam sesuai buku hal 249
    const forbidden = [
      'bayam', 'daun singkong', 'asparagus', 'kembang kol', 'kangkung', // Sayur
      'pisang', 'belimbing', 'alpukat', 'nangka', 'durian' // Buah (durian/nangka umum tinggi kalium)
    ]; 
    return forbidden.any((item) => lower.contains(item));
  }

  Future<void> _distributeIngredient(
    planner.FoodItem ingredient, 
    Map<String, List<FoodItem>> foodMap,
    List<KidneyMenuItem> pagi,
    List<KidneyMenuItem> snackPagi, 
    List<KidneyMenuItem> siang,
    List<KidneyMenuItem> snackSore, 
    List<KidneyMenuItem> malam,
  ) async {
    final name = ingredient.name.toLowerCase();
    final weight = ingredient.weight.toDouble();

    // 1. Beras / Nasi
    if (name.contains('beras') || name.contains('nasi')) {
      final portion = weight / 3;
      final dbItem = _pickRandom(foodMap['Pokok'], filterQuery: 'nasi');
      
      // Helper internal untuk mengurangi duplikasi kode
      void addTo(List<KidneyMenuItem> list, String urtLabel) {
        list.add(KidneyMenuItem(
          categoryLabel: 'Makanan Pokok',
          foodName: dbItem?.name ?? 'Nasi Putih',
          weight: portion,
          urt: urtLabel, 
          foodData: dbItem,
        ));
      }

      addTo(pagi, '1/3 porsi harian'); // Sesuaikan URT agar user paham
      addTo(siang, '1/3 porsi harian');
      addTo(malam, '1/3 porsi harian');
    }

    // 2. Maizena / Tepung (PENTING: Kalori Booster utk Ginjal)
    else if (name.contains('maizena') || name.contains('tepung') || name.contains('sagu')) {
      snackPagi.add(KidneyMenuItem(
        categoryLabel: 'Kue / Snack RP',
        foodName: 'Kue Talam/Semprit (Bahan: ${ingredient.name})',
        weight: weight,
        urt: ingredient.urt,
        foodData: null,
      ));
    }

    // 3. Telur
    else if (name.contains('telur')) {
      final dbItem = _pickRandom(foodMap['Lauk Hewani'], filterQuery: 'telur');
      pagi.add(KidneyMenuItem(
        categoryLabel: 'Lauk Hewani',
        foodName: dbItem?.name ?? 'Telur Rebus',
        weight: weight,
        urt: ingredient.urt,
        foodData: dbItem,
      ));
    }

    // 4. Daging Sapi
    else if (name.contains('daging') || name.contains('sapi')) {
      final dbItem = _pickRandom(foodMap['Lauk Hewani'], filterQuery: 'daging') ?? 
                     _pickRandom(foodMap['Lauk Hewani'], filterQuery: 'sapi');
      siang.add(KidneyMenuItem(
        categoryLabel: 'Lauk Hewani',
        foodName: dbItem?.name ?? 'Empal Daging',
        weight: weight,
        urt: ingredient.urt,
        foodData: dbItem,
      ));
    }

    // 5. Ayam / Ikan
    else if (name.contains('ayam') || name.contains('ikan')) {
      final isAyam = name.contains('ayam');
      final dbItem = _pickRandom(foodMap['Lauk Hewani'], filterQuery: isAyam ? 'ayam' : 'ikan');
      malam.add(KidneyMenuItem(
        categoryLabel: 'Lauk Hewani',
        foodName: dbItem?.name ?? (isAyam ? 'Ayam Panggang' : 'Ikan Pepes'),
        weight: weight,
        urt: ingredient.urt,
        foodData: dbItem,
      ));
    }

    // 6. Tempe / Tahu (Hati-hati fosfor, tapi jika ada di plan, distribusikan)
    else if (name.contains('tempe') || name.contains('tahu')) {
      // Logic split siang/malam sudah bagus
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
        final dbItem = _pickRandom(foodMap['Lauk Nabati']); // Random nabati for variety
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
    }

    // 7. Sayuran
    else if (name.contains('sayur')) {
      final portion = weight / 2;
      // Ambil 2 jenis sayur berbeda
      final dbItemA = _pickRandom(foodMap['Sayuran']);
      var dbItemB = _pickRandom(foodMap['Sayuran']);
      
      // Usahakan beda jenis jika data cukup
      if (foodMap['Sayuran']!.length > 1) {
          while(dbItemB == dbItemA) {
             dbItemB = _pickRandom(foodMap['Sayuran']);
          }
      }

      siang.add(KidneyMenuItem(
        categoryLabel: 'Sayuran',
        foodName: dbItemA?.name ?? 'Tumis Sayur',
        weight: portion,
        urt: '1/2 porsi (${ingredient.urt})', // Tampilkan URT asli sebagai referensi
        foodData: dbItemA,
      ));

      malam.add(KidneyMenuItem(
        categoryLabel: 'Sayuran',
        foodName: dbItemB?.name ?? 'Sup Sayur',
        weight: portion,
        urt: '1/2 porsi',
        foodData: dbItemB,
      ));
    }

    // 8. Buah & Gula/Madu (Selingan)
    // Code aslinya sudah bagus membagi ke Snack Pagi/Sore
    else if (name.contains('buah') || name.contains('pepaya')) {
         final portion = weight / 2;
         final dbItemA = _pickRandom(foodMap['Buah']);
         snackPagi.add(KidneyMenuItem(
           categoryLabel: 'Buah Potong', foodName: dbItemA?.name ?? 'Buah', 
           weight: portion, urt: '1 ptg sdg', foodData: dbItemA
         ));
         final dbItemB = _pickRandom(foodMap['Buah']);
         snackSore.add(KidneyMenuItem(
           categoryLabel: 'Buah Potong', foodName: dbItemB?.name ?? 'Buah', 
           weight: portion, urt: '1 ptg sdg', foodData: dbItemB
         ));
    }
    
    // Fallback gula/minyak/dll (Gunakan logika lama Anda, sudah oke)
    else if (name.contains('gula') || name.contains('madu')) {
        snackPagi.add(KidneyMenuItem(
           categoryLabel: 'Pemanis', foodName: ingredient.name, weight: weight, urt: ingredient.urt
        ));
    }
    else {
        // Default
        siang.add(KidneyMenuItem(categoryLabel: 'Tambahan', foodName: ingredient.name, weight: weight, urt: ingredient.urt));
    }
  }

  FoodItem? _pickRandom(List<FoodItem>? list, {String? filterQuery}) {
    if (list == null || list.isEmpty) return null;
    List<FoodItem> candidates = list;
    if (filterQuery != null) {
      final filtered = list.where((i) => i.name.toLowerCase().contains(filterQuery.toLowerCase())).toList();
      if (filtered.isNotEmpty) candidates = filtered;
    }
    return candidates[Random().nextInt(candidates.length)];
  }
}
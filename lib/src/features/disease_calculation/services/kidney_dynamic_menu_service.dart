// lib/src/features/disease_calculation/services/kidney_dynamic_menu_service.dart

import 'dart:math';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_menu_models.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/food_database_service.dart';
// Alias 'planner' agar tidak bentrok dengan FoodItem database
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_meal_planner_service.dart' as planner; 
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';

class KidneyDynamicMenuService {
  final FoodDatabaseService _dbService;

  KidneyDynamicMenuService(this._dbService);

  /// Fungsi utama untuk generate menu sehari penuh berdasarkan target protein
  Future<List<KidneyMealSession>> generateDailyMenu(int proteinTarget) async {
    // 1. Ambil semua data makanan dari DB untuk variasi menu matang
    final allFoods = await _dbService.getAllFoodItems();
    
    // Kelompokkan makanan agar mudah diambil (Simple in-memory caching)
    final Map<String, List<FoodItem>> foodMap = {
      'Pokok': [],
      'Lauk Hewani': [],
      'Lauk Nabati': [],
      'Sayuran': [],
      'Buah': [],
      'Susu': [],
      'Lemak': [],
      'Snack': [], // Tambahan kategori untuk Kue/Jajanan
      'Pemanis': [], // Gula, Madu, Sirup
    };

    for (var food in allFoods) {
      if (foodMap.containsKey(food.kelompokMakanan)) {
        foodMap[food.kelompokMakanan]!.add(food);
      } else {
        // Fallback categorization based on name strings if category not exact match
        final lowerName = food.name.toLowerCase();
        if (lowerName.contains('kue') || lowerName.contains('bolu') || lowerName.contains('puding')) {
           foodMap['Snack']?.add(food);
        } else if (lowerName.contains('gula') || lowerName.contains('madu') || lowerName.contains('sirup')) {
           foodMap['Pemanis']?.add(food);
        }
      }
    }

    // 2. Ambil syarat diet statis dari file planner (Resep Mentah yang Akurat)
    // List ini berisi item spesifik seperti "Maizena 15g", "Madu 20g" sesuai diet plan.
    final List<planner.FoodItem> dailyIngredients = planner.KidneyMealPlans.getPlanFor(proteinTarget);

    // 3. Siapkan wadah untuk 5 waktu makan
    List<KidneyMenuItem> pagi = [];
    List<KidneyMenuItem> snackPagi = []; // Pukul 10:00
    List<KidneyMenuItem> siang = [];
    List<KidneyMenuItem> snackSore = []; // Pukul 16:00
    List<KidneyMenuItem> malam = [];

    // 4. Logika Distribusi Bahan ke Waktu Makan
    // Kita iterasi setiap bahan dari syarat diet dan mendistribusikannya secara cerdas
    for (var ingredient in dailyIngredients) {
      await _distributeIngredient(
        ingredient, 
        foodMap, 
        pagi, 
        snackPagi, 
        siang, 
        snackSore, 
        malam
      );
    }

    // 5. Return hasil dalam bentuk Session yang berurutan
    return [
      KidneyMealSession(sessionName: 'Makan Pagi (06.00 - 08.00)', items: pagi),
      
      if (snackPagi.isNotEmpty)
        KidneyMealSession(sessionName: 'Selingan Pagi (10.00)', items: snackPagi),
        
      KidneyMealSession(sessionName: 'Makan Siang (12.00 - 13.00)', items: siang),
      
      if (snackSore.isNotEmpty)
        KidneyMealSession(sessionName: 'Selingan Sore (16.00)', items: snackSore),
        
      KidneyMealSession(sessionName: 'Makan Malam (18.00 - 19.00)', items: malam),
    ];
  }

  /// Helper untuk memecah total bahan mentah ke menu matang secara spesifik
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
    final urt = ingredient.urt;

    // --- LOGIKA DISTRIBUSI SPESIFIK BERDASARKAN BAHAN DIET ---
    
    // 1. Beras / Nasi -> Dibagi 3 Makan Utama
    if (name.contains('beras') || name.contains('nasi')) {
      final portionPerMeal = weight / 3;
      // Cari variasi nasi/bubur di DB
      final dbItem = _pickRandom(foodMap['Pokok'], filterQuery: 'nasi');
      
      // Gunakan nama bahan dari Planner (misal "Beras") tapi tampilkan sebagai menu matang ("Nasi Putih")
      // URT kita sesuaikan: "1/3 dari total"
      
      final itemPagi = KidneyMenuItem(
        categoryLabel: 'Makanan Pokok',
        foodName: dbItem?.name ?? 'Nasi Putih', 
        weight: portionPerMeal,
        urt: '1/3 total ($urt)', 
        foodData: dbItem,
      );
      
      pagi.add(itemPagi);
      siang.add(KidneyMenuItem(
        categoryLabel: 'Makanan Pokok', 
        foodName: itemPagi.foodName, 
        weight: portionPerMeal, 
        urt: '1/3 total', 
        foodData: dbItem
      ));
      malam.add(KidneyMenuItem(
        categoryLabel: 'Makanan Pokok', 
        foodName: itemPagi.foodName, 
        weight: portionPerMeal, 
        urt: '1/3 total', 
        foodData: dbItem
      ));
    }

    // 2. Maizena / Tepung -> Biasanya untuk Kue/Snack (Snack Pagi/Sore)
    else if (name.contains('maizena') || name.contains('tepung')) {
      // Masuk ke Snack Pagi (misal: Bubur Maizena / Kue)
      snackPagi.add(KidneyMenuItem(
        categoryLabel: 'Kue / Snack',
        foodName: 'Kue/Bubur dari Tepung (Maizena)',
        weight: weight,
        urt: urt,
        foodData: null, // User bisa cari resep spesifik
      ));
    }

    // 3. Telur -> Prioritas Makan Pagi
    else if (name.contains('telur')) {
      final dbItem = _pickRandom(foodMap['Lauk Hewani'], filterQuery: 'telur');
      pagi.add(KidneyMenuItem(
        categoryLabel: 'Lauk Hewani',
        foodName: dbItem?.name ?? 'Telur Rebus',
        weight: weight,
        urt: urt,
        foodData: dbItem,
      ));
    }

    // 4. Daging Sapi -> Makan Siang
    else if (name.contains('daging')) {
      final dbItem = _pickRandom(foodMap['Lauk Hewani'], filterQuery: 'daging') 
                  ?? _pickRandom(foodMap['Lauk Hewani'], filterQuery: 'sapi');
                  
      siang.add(KidneyMenuItem(
        categoryLabel: 'Lauk Hewani',
        foodName: dbItem?.name ?? 'Empal Daging',
        weight: weight,
        urt: urt,
        foodData: dbItem,
      ));
    }

    // 5. Ayam / Ikan -> Makan Malam (atau split jika item daging tidak ada)
    else if (name.contains('ayam') || name.contains('ikan')) {
      final dbItem = _pickRandom(foodMap['Lauk Hewani'], filterQuery: name.contains('ayam') ? 'ayam' : 'ikan');
      
      malam.add(KidneyMenuItem(
        categoryLabel: 'Lauk Hewani',
        foodName: dbItem?.name ?? (name.contains('ayam') ? 'Ayam Bakar' : 'Ikan Pesmol'),
        weight: weight,
        urt: urt,
        foodData: dbItem,
      ));
    }

    // 6. Tempe / Tahu (Nabati) -> Siang & Malam
    else if (name.contains('tempe') || name.contains('tahu')) {
      // Jika porsi kecil (< 50g), taruh di satu waktu makan saja (Siang)
      if (weight < 50) {
        final dbItem = _pickRandom(foodMap['Lauk Nabati'], filterQuery: name);
        siang.add(KidneyMenuItem(
          categoryLabel: 'Lauk Nabati',
          foodName: dbItem?.name ?? 'Tempe Goreng',
          weight: weight,
          urt: urt,
          foodData: dbItem,
        ));
      } else {
        // Jika porsi besar, bagi dua
        final portion = weight / 2;
        final dbItem = _pickRandom(foodMap['Lauk Nabati']);
        
        siang.add(KidneyMenuItem(
          categoryLabel: 'Lauk Nabati',
          foodName: dbItem?.name ?? 'Tempe Bacem',
          weight: portion,
          urt: '1/2 total ($urt)',
          foodData: dbItem,
        ));
        malam.add(KidneyMenuItem(
          categoryLabel: 'Lauk Nabati',
          foodName: dbItem?.name ?? 'Tahu Kukus',
          weight: portion,
          urt: '1/2 total',
          foodData: dbItem,
        ));
      }
    }

    // 7. Sayuran -> Siang & Malam
    else if (name.contains('sayur')) {
      final portion = weight / 2;
      final dbItemA = _pickRandom(foodMap['Sayuran']);
      final dbItemB = _pickRandom(foodMap['Sayuran']);

      siang.add(KidneyMenuItem(
        categoryLabel: 'Sayuran',
        foodName: dbItemA?.name ?? 'Tumis Labu Siam',
        weight: portion,
        urt: '1/2 porsi ($urt)',
        foodData: dbItemA,
      ));

      malam.add(KidneyMenuItem(
        categoryLabel: 'Sayuran',
        foodName: dbItemB?.name ?? 'Sup Wortel',
        weight: portion,
        urt: '1/2 porsi',
        foodData: dbItemB,
      ));
    }

    // 8. Buah / Pepaya -> Snack Pagi (10:00) & Snack Sore (16:00)
    else if (name.contains('buah') || name.contains('pepaya')) {
      final portion = weight / 2;
      
      // Snack Pagi
      final dbItemPagi = _pickRandom(foodMap['Buah']);
      snackPagi.add(KidneyMenuItem(
        categoryLabel: 'Buah-buahan',
        foodName: dbItemPagi?.name ?? 'Pepaya Potong',
        weight: portion,
        urt: '1/2 porsi ($urt)',
        foodData: dbItemPagi,
      ));

      // Snack Sore
      final dbItemSore = _pickRandom(foodMap['Buah']);
      snackSore.add(KidneyMenuItem(
        categoryLabel: 'Buah-buahan',
        foodName: dbItemSore?.name ?? 'Apel Malang',
        weight: portion,
        urt: '1/2 porsi',
        foodData: dbItemSore,
      ));
    }

    // 9. Minyak -> Didistribusikan ke pengolahan (Info saja)
    else if (name.contains('minyak')) {
      siang.add(KidneyMenuItem(
        categoryLabel: 'Pengolahan',
        foodName: 'Minyak untuk menumis',
        weight: weight / 2,
        urt: 'Secukupnya',
      ));
      malam.add(KidneyMenuItem(
        categoryLabel: 'Pengolahan',
        foodName: 'Minyak untuk menumis',
        weight: weight / 2,
        urt: 'Secukupnya',
      ));
    }

    // 10. Gula / Madu / Sirup -> Snack Pagi / Sore (Minuman/Kue)
    else if (name.contains('gula') || name.contains('madu') || name.contains('sirup')) {
       // Masukkan ke Snack Pagi sebagai pelengkap
       snackPagi.add(KidneyMenuItem(
        categoryLabel: 'Pemanis',
        foodName: ingredient.name, // "Madu" atau "Gula Pasir"
        weight: weight,
        urt: urt,
       ));
    }

    // 11. Susu / Tepung Susu -> Pagi atau Malam
    else if (name.contains('susu')) {
      // Cek apakah 'Tepung Susu' (biasanya untuk kue) atau 'Susu' (minum)
      if (name.contains('tepung')) {
         // Tepung susu -> Bahan kue (Snack Sore)
         snackSore.add(KidneyMenuItem(
          categoryLabel: 'Bahan Kue',
          foodName: ingredient.name,
          weight: weight,
          urt: urt,
         ));
      } else {
         // Susu cair/seduh -> Minum Pagi
         pagi.add(KidneyMenuItem(
          categoryLabel: 'Minuman',
          foodName: 'Susu Rendah Protein',
          weight: weight,
          urt: urt,
         ));
      }
    }

    // 12. Kue Protein Rendah -> Snack Sore
    else if (name.contains('kue')) {
       snackSore.add(KidneyMenuItem(
        categoryLabel: 'Kue / Snack',
        foodName: 'Kue Talam / Kue RP',
        weight: weight,
        urt: urt,
       ));
    }

    // Default fallback -> Masuk Siang
    else {
      siang.add(KidneyMenuItem(
        categoryLabel: 'Tambahan',
        foodName: ingredient.name,
        weight: weight,
        urt: urt,
      ));
    }
  }

  /// Helper untuk mengambil item acak dari list
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
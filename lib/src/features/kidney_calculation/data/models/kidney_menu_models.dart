// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\kidney_calculation\data\models\kidney_menu_models.dart

import 'package:aplikasi_diagnosa_gizi/src/features/food_database/data/models/food_item_model.dart';

/// Satu item makanan di dalam sesi menu rekomendasi harian.
class KidneyMenuItem {
  final String categoryLabel; // Label kategori, mis. "Sumber Karbohidrat"
  String foodName; // Nama makanan, mis. "Nasi Putih"
  double weight; // Berat dalam gram
  String urt; // Ukuran Rumah Tangga, mis. "1 gls"
  FoodItem? foodData; // Data lengkap dari Firestore (untuk detail gizi)

  KidneyMenuItem({
    required this.categoryLabel,
    required this.foodName,
    required this.weight,
    required this.urt,
    this.foodData,
  });
}

/// Satu sesi waktu makan beserta daftar itemnya.
class KidneyMealSession {
  final String sessionName;
  final List<KidneyMenuItem> items;

  KidneyMealSession({required this.sessionName, required this.items});
}

// lib\src\features\disease_calculation\services\kidney_menu_models.dart

import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';

/// Model untuk satu item makanan di dalam menu (mirip DmMenuItem)
class KidneyMenuItem {
  final String categoryLabel; // Label kategori (misal: "Sumber Karbohidrat")
  String foodName;            // Nama Makanan (misal: "Nasi Putih")
  double weight;              // Berat dalam gram
  String urt;                 // Ukuran Rumah Tangga (misal: "1 gls")
  FoodItem? foodData;         // Data lengkap dari database (untuk hitung gizi detail)

  KidneyMenuItem({
    required this.categoryLabel,
    required this.foodName,
    required this.weight,
    required this.urt,
    this.foodData,
  });
}

/// Model untuk satu sesi makan (Pagi / Siang / Malam / Selingan)
class KidneyMealSession {
  final String sessionName;      // Pagi, Siang, atau Malam
  final List<KidneyMenuItem> items;

  KidneyMealSession({
    required this.sessionName, 
    required this.items
  });
}
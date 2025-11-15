// lib\src\shared\widgets\food_filter_model.dart

import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';

class FoodFilterModel {
  final String? kelompokMakanan;
  final String? mentahOlahan;

  FoodFilterModel({
    this.kelompokMakanan,
    this.mentahOlahan,
  });

  /// Cek apakah ada filter yang aktif
  bool get isDefault {
    return kelompokMakanan == null && mentahOlahan == null;
  }

  /// Fungsi utama untuk memfilter
  bool matches(FoodItem foodItem) {
    // 1. Filter Kelompok Makanan
    final bool matchesKelompok;
    if (kelompokMakanan == null) {
      matchesKelompok = true;
    } else {
      matchesKelompok = foodItem.kelompokMakanan == kelompokMakanan;
    }

    // 2. Filter Status Mentah/Olahan
    final bool matchesStatus;
    if (mentahOlahan == null) {
      matchesStatus = true;
    } else {
      matchesStatus = foodItem.mentahOlahan == mentahOlahan;
    }

    return matchesKelompok && matchesStatus;
  }
}
// lib/src/features/disease_calculation/services/food_database_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';

class FoodDatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. WAJIB ADA: Method untuk mengambil SEMUA data ---
  // Ini dipanggil saat halaman search baru dibuka
  Future<List<FoodItem>> getAllFoodItems() async {
    try {
      final snapshot = await _db
          .collection('food_items')
          .orderBy('nama') // Urutkan sesuai abjad seperti FoodListPage
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => FoodItem.fromFirestore(doc))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching all food items: $e');
      return [];
    }
  }

  // --- 2. Pencarian Flexible (Client-side) ---
  // Menggunakan logika 'contains' agar mirip FoodListPage (bisa cari "Goreng" ketemu "Ayam Goreng")
  Future<List<FoodItem>> searchFoodByName(String query) async {
    try {
      if (query.isEmpty) return getAllFoodItems();

      // Ambil semua data dulu (cache friendly di Firestore jika sering diakses)
      final allFoods = await getAllFoodItems();
      final lowerQuery = query.toLowerCase();

      return allFoods.where((item) {
        // Logika persis FoodListPage: Cek Nama ATAU Kode
        final matchesName = item.name.toLowerCase().contains(lowerQuery);
        final matchesCode = item.code.toLowerCase().contains(lowerQuery);
        return matchesName || matchesCode; 
      }).toList();
      
    } catch (e) {
      print('Error searching food: $e');
      return [];
    }
  }

  // --- 3. Random Food (Tetap dipertahankan) ---
  Future<FoodItem?> getRandomFoodItemByCategory(String firestoreCategory) async {
    try {
      final snapshot = await _db
          .collection('food_items')
          .where('kelompok_makanan', isEqualTo: firestoreCategory)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final randomIndex = Random().nextInt(snapshot.docs.length);
        return FoodItem.fromFirestore(snapshot.docs[randomIndex]);
      }
      return null;
    } catch (e) {
      print('Error fetching random food: $e');
      return null;
    }
  }
}
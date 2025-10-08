// lib/src/features/disease_calculation/services/food_database_service.dart

import 'dart:math'; // Diperlukan untuk kelas Random
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';

class FoodDatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

   // Method baru untuk mengambil semua item makanan dari sebuah kategori
  Future<List<FoodItem>> getFoodItemsByCategory(String category) async {
    try {
      final snapshot = await _db
          .collection('food_database')
          .where('kelompok_makanan', isEqualTo: category)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => FoodItem.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching food items for category $category: $e');
      return [];
    }
  }

  // Mengambil item makanan secara acak berdasarkan kategori (kelompok makanan)
  Future<FoodItem?> getRandomFoodItemByCategory(String category) async {
    try {
      // Menggunakan 'kelompok_makanan' sesuai dengan model Anda
      final snapshot = await _db
          .collection('food_database')
          .where('kelompok_makanan', isEqualTo: category)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final randomIndex = Random().nextInt(snapshot.docs.length);
        final doc = snapshot.docs[randomIndex];
        
        // Menggunakan factory constructor 'fromFirestore' yang sudah ada di model Anda
        // Perhatikan bahwa kita perlu melakukan cast pada 'doc' ke tipe yang benar
        return FoodItem.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
      }
      return null;
    } catch (e) {
      print('Error fetching food item: $e');
      return null;
    }
  }
}
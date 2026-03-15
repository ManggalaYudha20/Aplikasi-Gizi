// lib/src/features/food_database/services/food_database_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/data/models/food_item_model.dart';

/// Service terpusat untuk semua operasi CRUD pada koleksi [food_items] di Firestore.
///
/// Semua akses ke [FirebaseFirestore] yang berkaitan dengan food_database
/// harus melalui class ini agar konsistensi dan testability terjaga.
class FoodDatabaseService {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('food_items');

  // ---------------------------------------------------------------------------
  // READ
  // ---------------------------------------------------------------------------

  /// Mengembalikan [Stream] yang memancarkan daftar [FoodItem] setiap kali
  /// data di Firestore berubah, diurutkan berdasarkan nama (a–z).
  Stream<List<FoodItem>> getFoodItemsStream() {
    return _collection.orderBy('nama').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => FoodItem.fromFirestore(
                    doc as DocumentSnapshot<Map<String, dynamic>>,
                  ))
              .toList(),
        );
  }

  // ---------------------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------------------

  /// Menambahkan dokumen baru ke koleksi [food_items].
  ///
  /// [data] adalah Map yang telah diformat sesuai skema Firestore
  /// (menggunakan key Bahasa Indonesia, mis. `'nama'`, `'energi'`, dst.).
  Future<void> addFoodItem(Map<String, dynamic> data) async {
    await _collection.add(data);
  }

  // ---------------------------------------------------------------------------
  // UPDATE
  // ---------------------------------------------------------------------------

  /// Memperbarui dokumen dengan [id] yang diberikan.
  ///
  /// [data] hanya perlu berisi field yang ingin diperbarui (partial update).
  Future<void> updateFoodItem(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  /// Menghapus dokumen dengan [id] yang diberikan secara permanen.
  Future<void> deleteFoodItem(String id) async {
    await _collection.doc(id).delete();
  }
}
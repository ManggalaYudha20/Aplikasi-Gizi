//lib\src\features\food_database\presentation\pages\delete_item_service.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';

class FoodItemService {
  // Fungsi untuk menampilkan dialog konfirmasi dan menghapus item
  static Future<void> deleteFoodItem(BuildContext context, FoodItem foodItem) async {
    // 1. Tampilkan dialog konfirmasi
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus "${foodItem.name}"?'),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    // 2. Jika pengguna menekan "Hapus", lanjutkan proses
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('food_items') // Pastikan nama koleksi ini benar
            .doc(foodItem.id)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          // Kembali ke halaman sebelumnya dan kirim sinyal untuk refresh
          Navigator.pop(context, true); 
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
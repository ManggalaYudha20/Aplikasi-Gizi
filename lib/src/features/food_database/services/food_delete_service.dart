// lib/src/features/food_database/services/food_delete_service.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/data/models/food_item_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/services/food_database_service.dart';

/// Menyediakan logika konfirmasi dan eksekusi penghapusan [FoodItem].
///
/// Dialog konfirmasi ditampilkan sebelum penghapusan dilakukan.
/// Operasi Firestore didelegasikan ke [FoodDatabaseService].
class FoodDeleteService {
  static final FoodDatabaseService _dbService = FoodDatabaseService();

  /// Menampilkan dialog konfirmasi kepada pengguna, lalu menghapus [foodItem]
  /// dari Firestore jika pengguna mengonfirmasi.
  ///
  /// Setelah berhasil, memanggil [Navigator.pop] dengan nilai `true` agar
  /// halaman pemanggil dapat me-refresh data bila diperlukan.
  static Future<void> deleteFoodItem(
    BuildContext context,
    FoodItem foodItem,
  ) async {
    // 1. Tampilkan dialog konfirmasi.
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          // Menambahkan Row untuk menempatkan Icon dan Text secara berdampingan
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Konfirmasi Hapus'),
            ],
          ),
          // Menyesuaikan teks agar lebih informatif
          content: Text(
            'Apakah Anda yakin ingin menghapus "${foodItem.name}" secara permanen? '           
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            // Mengubah TextButton menjadi ElevatedButton dengan warna merah
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Ya, Hapus'),
            ),
          ],
        );
      },
    );

    // 2. Batalkan jika pengguna tidak mengonfirmasi.
    if (confirm != true) return;

    // 3. Lakukan penghapusan melalui service.
    try {
      await _dbService.deleteFoodItem(foodItem.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        // Kembali ke halaman sebelumnya dan kirim sinyal refresh.
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
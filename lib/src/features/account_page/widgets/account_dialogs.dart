import 'package:flutter/material.dart';

class AccountDialogs {
  static Future<void> showSignOutConfirmation(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          // Menggunakan Row untuk menambahkan Ikon di sebelah teks judul
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red), // Ikon logout
              SizedBox(width: 8),
              Text('Konfirmasi Keluar'),
            ],
          ),
          content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            // Mengubah TextButton menjadi ElevatedButton dengan warna solid
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
              child: const Text('Ya, Keluar'),
            ),
          ],
        );
      },
    );
  }
  static Future<void> showDeleteAccountConfirmation(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Hapus Akun'),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin menghapus akun secara permanen? '
            'Semua data Anda akan hilang dan tindakan ini tidak dapat dibatalkan.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
              child: const Text('Ya, Hapus Akun'),
            ),
          ],
        );
      },
    );
  }

  static void showProfileImage(BuildContext context, String? imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(imageUrl, fit: BoxFit.cover)
              : Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: const Icon(Icons.person, size: 100, color: Colors.grey),
                ),
        ),
      ),
    );
  }
}
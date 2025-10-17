import 'package:aplikasi_diagnosa_gizi/src/login/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/fade_in_transition.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  // FUNGSI untuk menampilkan dialog konfirmasi KELUAR
  Future<void> _showSignOutConfirmationDialog(
    BuildContext context,
    AuthService authService,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // Pengguna bisa menutup dengan tap di luar
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Tutup dialog
              },
            ),
            TextButton(
              child: const Text('Keluar'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Tutup dialog
                await authService.signOut();
                // AuthWrapper akan menangani navigasi ke LoginScreen secara otomatis.
              },
            ),
          ],
        );
      },
    );
  }

  // FUNGSI _showDeleteConfirmationDialog TELAH DIHAPUS

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final User? user = authService.getCurrentUser();

    return Scaffold(
      backgroundColor: const Color.fromARGB(150, 255, 255, 255),
      appBar: CustomAppBar(
        title: 'Akun',
        subtitle: 'Halo, ${user?.displayName}!',
      ),
      body: Center(
        child: FadeInTransition(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (user?.photoURL != null)
                  CircleAvatar(
                    backgroundImage: NetworkImage(user!.photoURL!),
                    radius: 50,
                  ),
                const SizedBox(height: 20),
                Text(
                  user?.displayName ?? 'Pengguna',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? 'Tidak ada email',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Keluar'),
                    onPressed: () =>
                        _showSignOutConfirmationDialog(context, authService),
                  ),
                ),
                // PERBAIKAN: Tombol "Hapus Akun" dan SizedBox di bawahnya telah dihapus.
              ],
            ),
          ),
        ),
      ),
    );
  }
}

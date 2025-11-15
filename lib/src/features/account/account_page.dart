import 'package:aplikasi_diagnosa_gizi/src/login/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/fade_in_transition.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/version_info_app.dart';


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
              child: const Text('Keluar',style: TextStyle(color: Colors.red)),
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

  // --- TAMBAHKAN FUNGSI BARU DI SINI ---
  // FUNGSI untuk menampilkan gambar profil dalam dialog
  Future<void> _showFullImageDialog(
    BuildContext context,
    String imageUrl,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // Izinkan tutup dengan tap di luar
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor:
              Colors.transparent, // Latar belakang dialog transparan
          insetPadding: const EdgeInsets.all(10), // Padding di sekitar
          elevation: 0, // Tanpa bayangan
          child: InteractiveViewer(
            // Widget ini memungkinkan zoom dan pan
            panEnabled: true,
            minScale: 0.8,
            maxScale: 4.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain, // Pastikan gambar utuh
              // Tampilkan loading indicator saat gambar dimuat
              loadingBuilder:
                  (
                    BuildContext context,
                    Widget child,
                    ImageChunkEvent? loadingProgress,
                  ) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
              // Tampilkan ikon error jika gambar gagal dimuat
              errorBuilder:
                  (
                    BuildContext context,
                    Object exception,
                    StackTrace? stackTrace,
                  ) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 50,
                      ),
                    );
                  },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final User? user = authService.getCurrentUser();

    return Scaffold(
      backgroundColor: const Color.fromARGB(150, 255, 255, 255),
      appBar: CustomAppBar(
        title: 'Profil Akun',
        subtitle: 'Halo, ${user?.displayName}!',
      ),
      body: FadeInTransition(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (user?.photoURL != null)
                    GestureDetector(
                      onTap: () {
                        _showFullImageDialog(context, user.photoURL!);
                      },
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(user!.photoURL!),
                        radius: 50,
                      ),
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
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      _showSignOutConfirmationDialog(context, authService),
                  child: Row(
                    children: [
                      // 1. Grup Kiri: Ikon dan Teks
                      const Icon(Icons.logout),
                      const SizedBox(width: 12), // Jarak antara ikon dan teks
                      const Text('Keluar'),

                      // 2. Spacer Ajaib
                      const Spacer(), // Ini akan mengisi ruang di tengah
                      // 3. Ikon Kanan
                      const Icon(Icons.chevron_right), // Ini adalah ikon '>'
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(), 
            
           Padding(
              padding: const EdgeInsets.only(bottom: 16.0), 
              child: Column( // <--- GUNAKAN COLUMN DI SINI
                mainAxisSize: MainAxisSize.min, // Agar column hanya setinggi isinya
                children: [ // Jarak kecil antara copyright dan versi
                   const VersionInfoWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

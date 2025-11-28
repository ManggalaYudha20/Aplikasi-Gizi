// lib\src\features\account\account_page.dart

import 'package:aplikasi_diagnosa_gizi/src/login/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/fade_in_transition.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/version_info_app.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/services/user_service.dart';


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
      barrierDismissible: true, 
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent, 
          insetPadding: const EdgeInsets.all(10), 
          elevation: 0, 
          // --- PERBAIKAN DI SINI ---
          // Bungkus InteractiveViewer dengan GestureDetector
          child: GestureDetector(
            // Fungsi ini akan menutup dialog saat area gambar/kosong diketuk
            onTap: () {
              Navigator.of(dialogContext).pop();
            },
            // HitTestBehavior.translucent memastikan area kosong juga bisa diketuk
            behavior: HitTestBehavior.translucent, 
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain, 
                loadingBuilder: (
                  BuildContext context,
                  Widget child,
                  ImageChunkEvent? loadingProgress,
                ) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (
                  BuildContext context,
                  Object exception,
                  StackTrace? stackTrace,
                ) {
                  // Pastikan widget error mengisi ruang agar mudah diketuk
                  return Container(
                    alignment: Alignment.center,
                    width: double.infinity,
                    height: double.infinity,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 50,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Gagal memuat gambar.\nKetuk untuk menutup.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final UserService userService = UserService();
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

                  const SizedBox(height: 16),
                  FutureBuilder<String?>(
                    future: userService.getUserRole(), // Ambil role dari Firestore
                    builder: (context, snapshot) {
                      // Tampilkan loading kecil saat memuat
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 20, 
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      
                      // Jika data ada dan tidak null
                      if (snapshot.hasData && snapshot.data != null) {
                        // Format text agar lebih rapi (misal: "ahli_gizi" -> "Ahli Gizi")
                        String roleRaw = snapshot.data!;
                        String roleFormatted = roleRaw
                            .split('_')
                            .map((word) => word.isNotEmpty
                                ? '${word[0].toUpperCase()}${word.substring(1)}'
                                : '')
                            .join(' ');

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, 
                            vertical: 6
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal, // Warna background badge
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            roleFormatted, 
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      }
                      
                      // Jika error atau null (misal offline dan tidak ada cache), sembunyikan
                      return const SizedBox.shrink();
                    },
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

// lib\src\app\auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/login/auth_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/login/login_screen.dart';
import 'package:aplikasi_diagnosa_gizi/src/app/main_screen.dart';
import 'package:aplikasi_diagnosa_gizi/src/app/session_wrapper.dart';

/// Mendengarkan stream autentikasi Firebase dan mengarahkan pengguna
/// ke [MainScreen] (sudah login) atau [LoginScreen] (belum login).
///
/// Menggunakan `const` constructor agar tidak di-rebuild secara tidak perlu
/// oleh widget induk.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  // AuthService dibuat di sini — satu instance, tidak dibuat ulang tiap build.
  static final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    // Gunakan FutureBuilder untuk mendapatkan status autentikasi awal
    // yang sudah "settled" dari Firebase (termasuk restore sesi dari disk
    // setelah kill RAM). Ini mencegah:
    //   1. Flash halaman Login padahal user sebenarnya sudah login.
    //   2. Infinite loading karena StreamBuilder tanpa initialData yang
    //      menunggu event pertama yang mungkin tertunda.
    //
    // Setelah status awal didapat, gunakan StreamBuilder untuk merespons
    // perubahan sesi (login/logout) ke depannya.
    return FutureBuilder<User?>(
      future: _getInitialUser(),
      builder: (context, initSnapshot) {
        // Masih menunggu Firebase merestore sesi → tampilkan loading.
        if (initSnapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Status awal sudah didapat. Sekarang pantau perubahan berikutnya.
        return StreamBuilder<User?>(
          initialData: initSnapshot.data,
          stream: _authService.authStateChanges,
          builder: (context, snapshot) {
            final user = snapshot.data;

            // User sudah login → MainScreen (dibungkus SessionWrapper)
            if (user != null) {
              return SessionWrapper(
                key: UniqueKey(),
                child: MainScreen(key: UniqueKey()),
              );
            }

            // Belum login → LoginScreen
            return const LoginScreen();
          },
        );
      },
    );
  }

  /// Mengambil user saat ini, dengan jaminan Firebase sudah selesai
  /// inisialisasi. Menunggu event authStateChanges pertama (atau null
  /// setelah timeout) agar sesi persisten sempat direstore dari disk.
  Future<User?> _getInitialUser() async {
    try {
      // Tunggu event authStateChanges pertama. Ini akan emit null jika
      // memang belum login, atau User jika sesi berhasil direstore.
      // Timeout 5 detik sebagai pengaman agar tidak pernah gantung.
      return await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Fallback: kembalikan user saat ini jika stream tidak emit apa-apa.
      return FirebaseAuth.instance.currentUser;
    }
  }
}

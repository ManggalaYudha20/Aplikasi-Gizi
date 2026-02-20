// lib/src/app/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aplikasi_diagnosa_gizi/src/login/auth_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/login/login_screen.dart';
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
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Tampilkan loading saat Firebase belum selesai inisialisasi
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User sudah login → MainScreen
        if (snapshot.hasData) {
          // Bungkus MainScreen dengan SessionWrapper
          return const SessionWrapper(
            child: MainScreen(),
          );
        }

        // Belum login → LoginScreen
        return const LoginScreen();
      },
    );
  }
}
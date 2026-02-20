//lib\src\app\session_wrapper.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aplikasi_diagnosa_gizi/src/login/auth_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/app/auth_wrapper.dart'; // Tambahkan ini untuk navigasi ulang

class SessionWrapper extends StatefulWidget {
  final Widget child;
  const SessionWrapper({super.key, required this.child});

  @override
  State<SessionWrapper> createState() => _SessionWrapperState();
}

class _SessionWrapperState extends State<SessionWrapper> {
  String? _currentRole;
  bool _isInitialLoad = true;
  bool _isDialogShowing = false; // Mencegah dialog muncul tumpang tindih
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return widget.child;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _isInitialLoad) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          final doc = snapshot.data!;

          // KONDISI 1: Akun Pengguna Dihapus (atau sedang proses dibuat)
          if (!doc.exists) {
            // Mencegah Race Condition saat akun baru saja dibuat:
            // Berikan jeda toleransi 2 detik, lalu verifikasi ulang.
            Future.delayed(const Duration(seconds: 2), () async {
              if (!mounted || _isDialogShowing) return;
              
              // Verifikasi ulang apakah dokumennya memang benar-benar tidak ada
              final verifyDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
              if (!verifyDoc.exists && mounted && !_isDialogShowing) {
                _showDeletedAccountDialog();
              }
            });
            // Tahan layar di status loading selagi menunggu verifikasi
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // KONDISI 2: Role Pengguna Berubah
          final data = doc.data() as Map<String, dynamic>?;
          final role = data?['role'] as String?;

          if (_isInitialLoad) {
            _currentRole = role;
            _isInitialLoad = false;
          } else if (_currentRole != role && role != null) {
            _currentRole = role; // Update lokal segera agar tidak ter-trigger berulang
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_isDialogShowing) {
                _showRoleChangedDialog();
              }
            });
          }
        }

        return widget.child;
      },
    );
  }

  void _showDeletedAccountDialog() {
    _isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sesi Berakhir'),
        content: const Text('Akun Anda telah dihapus oleh Admin. Anda akan dikeluarkan dari aplikasi.'),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              _isDialogShowing = false;
              await _authService.signOut(); // Akan memicu AuthWrapper melempar user ke LoginScreen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRoleChangedDialog() {
    _isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Perubahan Hak Akses'),
        content: const Text('Role/Hak akses Anda telah diubah oleh Admin. Aplikasi perlu dimuat ulang untuk menerapkan perubahan.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _isDialogShowing = false;
              
              // PERBAIKAN: Hapus seluruh tumpukan layar yang ada, dan paksa jalankan 
              // AuthWrapper dari nol agar MainScreen & Bottom Navbar membaca ulang role.
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthWrapper()),
                (route) => false,
              );
            },
            child: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}
// lib/src/app/session_wrapper.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aplikasi_diagnosa_gizi/src/login/auth_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/app/auth_wrapper.dart';

class SessionWrapper extends StatefulWidget {
  final Widget child;
  const SessionWrapper({super.key, required this.child});

  @override
  State<SessionWrapper> createState() => _SessionWrapperState();
}

class _SessionWrapperState extends State<SessionWrapper> {
  String? _currentRole;
  bool _isDialogShowing = false;
  bool _isInitialLoad = true;

  StreamSubscription<DocumentSnapshot>? _userDocSubscription;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _userDocSubscription?.cancel();
    super.dispose();
  }

  void _startListening() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userDocSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) async {
      if (!mounted) return;

      // KONDISI 1: Dokumen tidak ada — kemungkinan akun dihapus
      if (!doc.exists) {
        // Toleransi race condition saat akun baru dibuat
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;

        final verify = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!verify.exists && mounted && !_isDialogShowing) {
          _showDeletedAccountDialog();
        }
        return;
      }

      // KONDISI 2: Deteksi perubahan role
      final data = doc.data();
      final role = data?['role'] as String?;

      if (_isInitialLoad) {
        // Simpan role awal, jangan tampilkan dialog
        _currentRole = role;
        _isInitialLoad = false;
      } else if (role != null && role != _currentRole) {
        // Role berubah — update dulu lalu tampilkan dialog
        _currentRole = role;
        if (!_isDialogShowing) {
          _showRoleChangedDialog();
        }
      }
    }, onError: (e) {
      debugPrint('SessionWrapper stream error: $e');
    });
  }

  void _showDeletedAccountDialog() {
    _isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Sesi Berakhir'),
        content: const Text(
          'Akun Anda telah dihapus oleh Admin. '
          'Anda akan dikeluarkan dari aplikasi.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              _isDialogShowing = false;
              await _authService.signOut();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) => _isDialogShowing = false);
  }

  void _showRoleChangedDialog() {
    _isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Color(0xFF009444)),
            SizedBox(width: 8),
            Text('Perubahan Hak Akses'),
          ],
        ),
        content: const Text(
          'Role/Hak akses Anda telah diubah oleh Admin.\n\n'
          'Aplikasi perlu dimuat ulang untuk menerapkan perubahan.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _isDialogShowing = false;

              // Hapus seluruh stack dan jalankan AuthWrapper ulang
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthWrapper()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Muat Ulang'),
          ),
        ],
      ),
    ).then((_) => _isDialogShowing = false);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
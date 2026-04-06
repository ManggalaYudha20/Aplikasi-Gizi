// lib/src/app/session_wrapper.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/login/auth_service.dart';
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

  // Gunakan flag stabil: role dianggap sudah "siap" setelah snapshot
  // pertama + jeda 2 detik (menunggu auth/token Firebase settled)
  bool _roleReady = false;

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
    // 1. Pantau status autentikasi dari Firebase Auth terlebih dahulu
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        // Jika akun di Firebase Auth dihapus, hentikan listener
        _userDocSubscription?.cancel();
        return;
      }

      // Pastikan listener lama dibatalkan sebelum membuat listener baru
      _userDocSubscription?.cancel();

      // 2. Mulai pantau dokumen user di Firestore
      _userDocSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) async {
        if (!mounted) return;

        // ── KONDISI 1: Dokumen tidak ada ───────────────────────────────────
        if (!doc.exists) {
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) return;

          // Verifikasi ulang (tambahkan penanganan error jika akses langsung ditolak)
         DocumentSnapshot? verify;
          try {
            verify = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
          } catch (e) {
            // Jika ditolak (permission-denied), biarkan verify tetap null
            verify = null; 
          }

          // Sekarang pengecekan verify == null valid dan aman
          if ((verify == null || !verify.exists) && mounted && !_isDialogShowing) {
            _showDeletedAccountDialog();
          }
          return;
        }

        // ── KONDISI 2: Ambil role dari dokumen ─────────────────────────────
        final data = doc.data();
        final role = data?['role'] as String?;
        if (role == null) return;

        if (!_roleReady) {
          _currentRole = role;
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) return;

          final freshDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get()
              .catchError((_) => doc); // Fallback ke dokumen awal jika error
              
          final freshRole = freshDoc.data()?['role'] as String?;
          _currentRole = freshRole ?? role;
          _roleReady = true;

          debugPrint('SessionWrapper: role awal = $_currentRole');
          return;
        }

        // ── KONDISI 3: Role berubah ────────────────────────────────────────
        if (role != _currentRole) {
          debugPrint('SessionWrapper: role berubah $_currentRole → $role');
          _currentRole = role;
          if (!_isDialogShowing) {
            _showRoleChangedDialog();
          }
        }
      }, onError: (e) {
        debugPrint('SessionWrapper stream error: $e');
        
        // PENANGANAN KRUSIAL: Tangkap error Permission Denied
        // Jika dokumen dihapus dan rule menolak akses, kick user tersebut
        if (e is FirebaseException && e.code == 'permission-denied') {
          if (mounted && !_isDialogShowing) {
             debugPrint('SessionWrapper: Akses ditolak, mengeluarkan akun...');
            _showDeletedAccountDialog();
          }
        }
      });
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
            Flexible(child: Text('Perubahan Hak Akses')),
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
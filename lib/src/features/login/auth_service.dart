// lib/src/login/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? getCurrentUser() => _auth.currentUser;

  // ─────────────────────────────────────────
  // GOOGLE SIGN IN
  // ─────────────────────────────────────────
  Future<UserCredential?> signInWithGoogle() async {
    if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS &&
      defaultTargetPlatform != TargetPlatform.macOS) {
    throw Exception('Google Sign In tidak didukung di platform ini.');
  }
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userRef = _firestore.collection('users').doc(user.uid);
        final doc = await userRef.get();

        if (!doc.exists) {
          final defaultRole = await _getDefaultRole();
          await userRef.set({
            'displayName': user.displayName,
            'email': user.email,
            'photoURL': user.photoURL,
            'role': defaultRole,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          });
        } else {
          await userRef.update({'lastLogin': FieldValue.serverTimestamp()});
        }
      }

      return userCredential;
    } catch (e) {
      debugPrint('Error Google sign-in: $e');
      throw Exception('Gagal masuk dengan Google. Silakan coba lagi.');
    }
  }

  // ─────────────────────────────────────────
  // EMAIL & PASSWORD SIGN IN
  // ─────────────────────────────────────────
  Future<UserCredential?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;

      if (user != null) {
        // Blokir login jika email belum diverifikasi
        if (!user.emailVerified) {
          await _auth.signOut();
          throw Exception(
            'Email kamu belum diverifikasi.\n'
            'Cek inbox dan klik link verifikasi yang dikirim saat pendaftaran.',
          );
        }

        final userRef = _firestore.collection('users').doc(user.uid);
        final doc = await userRef.get();

        if (!doc.exists) {
          final defaultRole = await _getDefaultRole();
          await userRef.set({
            'displayName': user.displayName ?? 'Pengguna Email',
            'email': user.email,
            'photoURL': user.photoURL ?? '',
            'role': defaultRole,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          });
        } else {
          await userRef.update({'lastLogin': FieldValue.serverTimestamp()});
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error Email Login: ${e.message}');
      throw Exception(e.message ?? 'Gagal masuk dengan Email/Password.');
    }
  }

  // ─────────────────────────────────────────
  // REGISTER
  // ─────────────────────────────────────────
  Future<UserCredential?> registerWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(name);

        // Kirim email verifikasi otomatis setelah daftar
        await user.sendEmailVerification();

        final defaultRole = await _getDefaultRole();

        await _firestore.collection('users').doc(user.uid).set({
          'displayName': name,
          'email': user.email,
          'photoURL': '',
          'role': defaultRole,
          'emailVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error Register: ${e.message}');
      if (e.code == 'weak-password') {
        throw Exception('Password terlalu lemah. Gunakan minimal 6 karakter.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception(
          'Email ini sudah terdaftar. Silakan login atau gunakan email lain.',
        );
      }
      throw Exception(e.message ?? 'Gagal mendaftar.');
    } catch (e) {
      debugPrint('Error saat register: $e');
      throw Exception('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  // ─────────────────────────────────────────
  // KIRIM ULANG EMAIL VERIFIKASI
  // ─────────────────────────────────────────
  Future<void> resendVerificationEmail() async {
    final User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // ─────────────────────────────────────────
  // CEK STATUS VERIFIKASI (reload dari server)
  // ─────────────────────────────────────────
  Future<bool> checkEmailVerified() async {
    final User? user = _auth.currentUser;
    if (user == null) return false;

    // Reload data terbaru dari Firebase
    await user.reload();
    final refreshed = _auth.currentUser;

    if (refreshed != null && refreshed.emailVerified) {
      // Update flag di Firestore juga
      await _firestore.collection('users').doc(refreshed.uid).update({
        'emailVerified': true,
        'lastLogin': FieldValue.serverTimestamp(),
      });
      return true;
    }
    return false;
  }

  // ─────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────
  Future<void> signOut() async {
  // Google Sign In tidak support Windows
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    await _googleSignIn.signOut();
  }
  await _auth.signOut();
}

  // ─────────────────────────────────────────
  // HAPUS AKUN
  // ─────────────────────────────────────────
  Future<void> deleteAccount() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // 1. Hapus data pengguna dari Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        
        // 2. Putuskan sesi Google Sign-In lokal (untuk Android/iOS)
        if (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS) {
          try {
            await _googleSignIn.disconnect(); // Cabut akses sepenuhnya
          } catch (e) {
            debugPrint('Google disconnect failed, trying signout: $e');
            await _googleSignIn.signOut(); // Fallback jika disconnect gagal
          }
        }

        // 3. Hapus akun dari Firebase Auth
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuth Error saat menghapus akun: ${e.message}');
      rethrow; // <-- Menggunakan rethrow untuk mempertahankan stack trace asli
    } catch (e) {
      debugPrint('Error umum saat menghapus akun: $e');
      throw Exception('Gagal menghapus akun. Silakan coba lagi.');
    }
  }

  // ─────────────────────────────────────────
  // HELPER PRIVATE
  // ─────────────────────────────────────────
  Future<String> _getDefaultRole() async {
    try {
      final settingsDoc = await _firestore
          .collection('settings')
          .doc('app_settings')
          .get();
      if (settingsDoc.exists && settingsDoc.data() != null) {
        return settingsDoc.data()!['default_role'] ?? 'tamu';
      }
    } catch (e) {
      debugPrint('Gagal membaca default_role: $e');
    }
    return 'tamu';
  }
}
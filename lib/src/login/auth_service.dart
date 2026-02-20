// lib/src/login/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream untuk memantau perubahan status autentikasi
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // ## FUNGSI YANG DIPERBAIKI ##
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Pengguna membatalkan proses sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        final userRef = _firestore.collection('users').doc(user.uid);
        final doc = await userRef.get();

        if (!doc.exists) {
          String defaultRole = 'tamu'; // Role bawaan jika gagal mengambil pengaturan
          
          try {
            // Cek dokumen pengaturan global di koleksi 'settings'
            final settingsDoc = await _firestore.collection('settings').doc('app_settings').get();
            if (settingsDoc.exists && settingsDoc.data() != null) {
              // Jika pengaturan ada, gunakan nilai dari database
              defaultRole = settingsDoc.data()!['default_role'] ?? 'tamu';
            }
          } catch (e) {
            debugPrint('Gagal membaca pengaturan default_role: $e');
          }

          await userRef.set({
            'displayName': user.displayName,
            'email': user.email,
            'photoURL': user.photoURL,
            'role': defaultRole, // Default role
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          });
        } else {
          // Update last login
          await userRef.update({'lastLogin': FieldValue.serverTimestamp()});
        }
      }

      return userCredential;
    } catch (e) {
      debugPrint('Error saat sign-in dengan Google: $e');
      throw Exception('Gagal masuk dengan Google. Silakan coba lagi.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Hapus akun (jika diperlukan)
  Future<void> deleteAccount() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();
      }
    } catch (e) {
      debugPrint('Error saat menghapus akun: $e');
      // Mungkin perlu re-autentikasi
    }
  }
}

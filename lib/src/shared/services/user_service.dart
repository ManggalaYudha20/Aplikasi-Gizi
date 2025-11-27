//lib\src\shared\services\user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Kelas ini bertanggung jawab untuk semua interaksi yang terkait
/// dengan data pengguna di Firestore, seperti mengambil role.
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mengambil role dari pengguna yang sedang login dari koleksi 'users'.
  ///
  /// Mengembalikan [String] yang berisi nama role jika berhasil,
  /// atau `null` jika tidak ada pengguna yang login atau terjadi error.
  Future<String?> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) {
      // Jika tidak ada pengguna yang login, tidak ada role yang bisa diambil.
      return null;
    }

    try {
      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (docSnapshot.exists) {
        // Jika dokumen ada, kembalikan nilai dari field 'role'.
        return docSnapshot.data()?['role'];
      } else {
        // Jika dokumen tidak ada (kasus yang jarang terjadi setelah login),
        // kembalikan role default atau null.
        return 'tamu';
      }
    } catch (e) {
      print("--- Error fetching user role: $e ---");
      // Jika terjadi error saat komunikasi dengan Firestore, kembalikan null.
      return null;
    }
  }

  // Anda bisa menambahkan fungsi lain di sini di masa depan,
  // misalnya: Future<void> updateDisplayName(String newName) { ... }
}
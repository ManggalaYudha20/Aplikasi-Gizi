import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/admin/models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Stream data user yang sudah dikonversi ke List<UserModel>
  Stream<List<UserModel>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  // Update Role tunggal
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole.toFirestoreValue,
      });
    } catch (e) {
      throw Exception('Gagal memperbarui role: $e');
    }
  }

  // Hapus User Tunggal
  Future<void> deleteUser(String userId) async {
    try {
      WriteBatch batch = _firestore.batch();

      // 1. Siapkan referensi dokumen user yang akan dihapus
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      batch.delete(userRef);

      // 2. Cari semua data pasien yang dimiliki oleh ahli gizi ini
      // CATATAN: Sesuaikan nama koleksi 'patients' dan field 'userId' dengan struktur database Anda.
      // Jika pasien berada di sub-koleksi user, gunakan: await userRef.collection('patients').get();
      QuerySnapshot patientSnapshot = await _firestore
          .collection('patients') 
          .where('createdBy', isEqualTo: userId) 
          .get();

      // Tambahkan instruksi hapus pasien ke dalam batch
      for (var doc in patientSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 3. Eksekusi penghapusan secara bersamaan
      await batch.commit();
    } catch (e) {
      throw Exception('Gagal menghapus user dan data pasien: $e');
    }
  }
}
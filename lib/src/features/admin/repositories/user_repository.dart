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
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Gagal menghapus user: $e');
    }
  }

  // Penghapusan Massal (Batch Write)
  Future<void> batchDeleteUsers(List<String> userIds) async {
    if (userIds.isEmpty) return;

    WriteBatch batch = _firestore.batch();
    for (String id in userIds) {
      batch.delete(_firestore.collection('users').doc(id));
    }

    try {
      await batch.commit();
    } catch (e) {
      throw Exception('Gagal melakukan penghapusan massal: $e');
    }
  }
}
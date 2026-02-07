import 'package:aplikasi_diagnosa_gizi/src/features/admin/models/user_model.dart';

class UserManagementLogic {
  // Fungsi murni (Pure Function) untuk memfilter dan mengurutkan data
  // UI tinggal memanggil fungsi ini tanpa perlu tahu logika internalnya
  static List<UserModel> processUsers({
    required List<UserModel> allUsers,
    required String searchQuery,
  }) {
    // 1. Filtering
    final filteredUsers = allUsers.where((user) {
      return user.matchesSearch(searchQuery);
    }).toList();

    // 2. Sorting berdasarkan Prioritas Role
    // Admin (1) -> Ahli Gizi (2) -> Tamu (3) -> Nama (A-Z)
    filteredUsers.sort((a, b) {
      int roleComparison = a.role.priority.compareTo(b.role.priority);
      if (roleComparison != 0) {
        return roleComparison;
      }
      // Jika role sama, urutkan berdasarkan nama
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });

    return filteredUsers;
  }
}
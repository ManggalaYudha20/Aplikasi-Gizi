// lib/src/features/admin/models/user_filter_model.dart

import 'package:aplikasi_diagnosa_gizi/src/features/admin/models/user_model.dart';

class UserFilterModel {
  final UserRole? role;

  UserFilterModel({this.role});

  // Helper untuk mengecek apakah filter sedang aktif
  bool get isFiltering => role != null;
}